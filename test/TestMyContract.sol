pragma solidity ^0.5.8;
import "../contracts/Factory2.sol";
import "@openzeppelin/contracts/utils/Address.sol";

//this is a sample contract
// it has some constructor parameters that define its state.
contract MyContract {
    string public name;

    event Created(string a);
    
    constructor(string memory _name) public {
        name=_name;
        emit Created(name);
    }
}

//this is a generated factory interface for class MyContract.
// it has 2 methods. both have exact same param signature as the real constructor - with added "salt" as first param
// (currently genreated manually. can easily have a script to generate it)
interface IMyContractFactory {
    function create(string calldata a, uint id) external returns (MyContract);
    function getAddress(string calldata a, uint id) view external returns (address);
}


//this is a generated library to create an IMyContractFactory instance
library MyContractFactory {
    function createFactory() internal returns (IMyContractFactory) {
        return IMyContractFactory(address(new Factory2( type(MyContract).creationCode, IMyContractFactory(0).create.selector)));
    }
    
}

contract Atest{
    using Address for address;
    
    IMyContractFactory public f;
    constructor() public {
        //create an instance of the factory. it is important to use the same instance, since the factory
        // address is part of the generated object address.
        f = MyContractFactory.createFactory();
    }
    
    function test() public {
        IMyContractFactory fact = MyContractFactory.createFactory();
        string memory name = "asd";
        uint id=123;
        address addr1 = fact.getAddress(name,id);
        require( !addr1.isContract(), "contract must not exist at start");
        MyContract obj = fact.create(name,id);
        require( address(obj).isContract(), "contract must get deployed by calling create()");
        require( addr1 == address(obj), "getAddress() must return the same address as create()" );
    }
    
}