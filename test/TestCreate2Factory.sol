pragma solidity ^0.5.8;
import "../contracts/MyContract.sol";
import "../contracts/MyContractFactory.sol";

contract TestCreate2Factory {
    using Address for address;

    uint count;
    IMyContractFactory public fact;
    address addr;
    MyContract obj;
    
    constructor() public {
        fact = MyContractFactory.createFactory();
    }

    function testGetAddrBeforeCreate() public {
        addr = fact.getAddress("hello",1);
        require( !addr.isContract(), "getAddress should return address before deployment");
    }

    function testCreateObj() public {
        obj = fact.create("hello",1);
        require( address(obj).isContract(), "create should return address of real object");
        require( address(obj)==addr, "create should return the same address as getAddress()" );
    }

    function testParamsAffectAddress() public {
        count++;
        address addr2 = fact.getAddress("world",1);
        require( addr2!= addr, "different params nonce should return different address");
    }


    function testCreateAgain_fails() public {
        count++;
        require( address(fact.create("hello",1)) == address(0), "create should fail when called again" );
    }

    function testGetAddressAgain_sameaddr() public {
        count++;
        require( fact.getAddress("hello",1) == addr, "getAddress should return same address even after creation");
    }

    function testGetAddressNewSalt_newaddress() public {
        address addr2 = fact.setSalt(1).getAddress("hello",1);
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
