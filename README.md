
# Simple CREATE2 Library

## What is it

A simple library that allows using CREATE2 in a fully type-safe manner, without dealing with assembly language.

## What is CREATE2 ?

Its a way to have an address of a contract, based on its code and parameters - before actually deploying it.

There are several articles that explain in depth what `CREATE2` does, and what is it good for, 
like [Vitalik’s Original EIP](https://eips.ethereum.org/EIPS/eip-1014) and [OpenZeppelin’s blog](https://blog.openzeppelin.com/getting-the-most-out-of-create2/).

## What is the problem ?

There is complete lack of support in Solidity...

## Enters create2-helper library.


With this library, we create a **type-safe factory** for our contract.
- For each contract we want to use, we have a factory object.
- The factory has a `create` function with all the parameters of the **constructor** of our class.
- There is a `getAddress` function, with the same parameters, which can return the same address that `create` would 
  return - event before the object is created. 

### Sample code 

(the code below runs, and of course, all tests succeed)

```solidity
import "./MyContract.sol";
import "./MyContractFactory.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Sample {
    using Address for address;

    function testFactory() public {
        
        string memory name = "hello";
        uint age = 25;
        
        IMyContractFactory fact = MyContractFactory.createFactory();
        address addr1 = fact.getAddress(name,age);
        require( !addr1.isContract(), "contract must not exist at start");
        MyContract obj = fact.create(name,age);
        require( obj.age() == age );
        require( address(obj).isContract(), "contract must get deployed by calling create()");
        require( addr1 == address(obj), "getAddress() must return the same address as create()" );
    }

}
```

## Creating the factory 

But how do we create the above `MyContractFactory` and its interface ?

The `IMyContractFactory` interface has 2 methods `create` and `getAddress`, both with the same parameters list of the constructor.

The `MyContractFactory.createFactory` function created with the help of `Factory2` helper contract, described below.

But you don’t have to create these yourself: We provided a tool `createFactory2` , to create the factory classes for 
each of your contracts.

Note that you would usually use this tool exactly once for your contract - or when you change the 
**constructor parameters**. You don't have to re-generate it when the code of the contract is modified.
 
## Some salt and pepper…

If you read the `CREATE2` definition, you’d notice that something is missing: `CREATE2`’s address depends also on a **salt** value.

Such a salt is required, so we could create multiple distinct objects even with the same set of constructor parameters.

Unfortunately, due to implementation issue (described in the next "***Under the Hood***" section) our parameter list of
the `create`/`getAddress` methods need to be strictly the same as the constructor’s parameter list, and we can’t add 
an extra **salt** parameter.

Still, we provide 2 ways in which we still can add some salt:

1. The factory has a `setSalt` method. You can call it just before creating the object, e.g.: `myFactory.setSalt(123).create()` 
This has the drawback of wasting 20000 gas (you can reduce the waste to 5000, by calling myFactory.setSalt(0) after creating your object).

1. By passing a `-S` parameter to our `createFactory2` tool, it will add an **extra parameter** to the constructor's parameter list.
    this parameter (aptly named "*salt*") is used for the address calculation, but is not passed visible to the constructor, and thus acts
    just like the "standard" CREATE2 salt value.
    The downside of this method is that the calculation of the address using this "salt" is different than the `CREATE2` spec. 
    Our factory will work perfectly with it, but if you want o calculate the address yourself, without the library code, you'll need to
    be careful to include this "undocumented" parameter.
    
    Note that adding the `-S` parameter will also remove the `setSalt` method, since they should not be used together.
    
## Under the hood

If you want to understand how the above factory was created — read on…

As we could see, we created a custom factory interface for each contract — We have to, since it depends on the
constructor parameters specific to that contract, and of course, depends on the actual code of that contract.

If you look at the factory code, it looks like this:

    library MyContractFactory {
      function createFactory() internal returns (IMyContractFactory) {
        return IMyContractFactory(address(
          new Factory2( type(MyContract).creationCode,
            IMyContractFactory(0).create.selector)) );
      }
    }

At first glance, it looks **completely insane**: It doesn’t bother to implement our contract-specific interface methods. 
It’s a single-line, creating an instance of a library contract (`Factory2` ), and **casting** it into an interface it 
doesn’t implement ( `IMyContractFactory`) .

In order to understand how this works, we need to understand some of the underlying solidity constructs:

Constructor parameters are passed by appending the encoded parameters at the end of the construction code. solidity 
provides us the constructor code by calling the cryptic line `type(MyContract).constructionCode`.

Function parameters are appended to the function "signature" — a 4-byte identifier. Together (signature and params),
they are accessible in every solidity function as msg.data.

The last "magic ingredient" is the **default function** of the Factory2 class: This method gets called for any 
invocation of the class with unknown method.

We create an instance of the `Factory2` class, and **cast** it into the factory interface — not bothering to implement 
any of the methods. Thus the **default function** is called, for both create and getAddress (and theoretically, 
and other function in the interface)

The Factory2 is constructed with 2 parameters: the initialization code and the "create" function selector 
(note that knowing its name is "create" is not enough, since a selector encodes the complete list of parameter types too)

when the **default function** gets invoked, it extracts the parameters, and appends them to the construction code.

Now if the call was originally to the "create" selector, it calls CREATE2 to create that object. Otherwise, it executes
the calculation of the address, as per the CREATE2[ EIP1014](https://eips.ethereum.org/EIPS/eip-1014).

The one last magic sauce is to return that address: solidity **default function** doesn’t allow us to define a 
eturn value — but we have to, so we resort to some assembly code to the return the generated address…

## Standardizing the interface.

We believe that CREATE2 is an important addition to the EVM, and as such, also an important feature of the Solidity
language.

While **using** the above factory is very simple, **creating** one requires an external tool to expose the constructor's
signature, and create the boilerplate code of the factory

We purpose to add these 2 methods to the compiler's "Meta type information" structure, and of course, automatically 
use the contract's constructor params:
 
This way, these methods should be accessible as:

```solidity
type(MyContract).getAddress(params…)
type(MyContract).create.salt(1)(params…)
```


