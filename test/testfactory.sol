pragma solidity ^0.5.8;
import "../contracts/MyContract.sol";
import "../contracts/MyContractFactory.sol";



contract testfactory {
    using Address for address;

    IMyContractFactory fact;
    address addr;
    MyContract obj;
    function testCreateFactory() public {
        fact = MyContractFactory.createFactory();
    }

    function testGetAddrBeforeCreate() public {
        addr = fact.getAddress("hello");
        require( !addr.isContract(), "getAddress should return address before deployment");
    }

    function testCreateObj() public {
        obj = fact.create("hello");
        require( address(obj).isContract(), "create should return address of real object");
        require( address(obj)==addr, "create should return the same address as getAddress()" );
    }

    function testParamsAffectAddress() public {
        address addr2 = fact.getAddress("world");
        require( addr2!= addr, "different params nonce should return different address");
    }


    function testCreateAgain() public {
        require( address(fact.create("hello")) == address(0), "create should fail when called again" );
    }

    function testGetAddressAgain() public {
        (this);
        require( fact.getAddress("hello") == addr, "getAddress should return same address even after creation");
    }

    function testGetAddressNewSalt() public {
        address addr2 = fact.setSalt(1).getAddress("hello");
        require( addr2!= addr, "new nonce should return different address");
    }


}

//truffle test chokes when importing...
// import "@openzeppelin/contracts/utils/Address.sol";

library Address {
    function isContract(address addr) internal view returns(bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size!=0;
    }
}
