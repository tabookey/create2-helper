pragma solidity ^0.5.8;
import "@0x/contracts-utils/contracts/src/LibBytes.sol";

/*
 * Helper class for creating contracts with create2
 * usage:
 *  use the helper script "genFactory2 <mycontract.abi>". It will generate a file name MyContractFactory.sol,
 *  with a method MyContractFactory.create() to create the factory.
 * The returned factory object has 2 methods:
 *  create() - a method to create a new MyContract instance.
 *  getAddress() - a method to return the same address as "create()" - even before it is created.
 * The generated object depends on the constructor paramters and salt. Both methods have "salt" as first parameter,
 * and all other paramters are passed as-is to the contract's constructor.
 */
contract Factory2 {

    using LibBytes for bytes;
    bytes creationCode;
    bytes4 ctrSelector;

    constructor(bytes memory _creationCode, bytes4 _ctrSelector) public {
        creationCode = _creationCode;
        ctrSelector = _ctrSelector;
    }

    uint public salt;

    function setSalt(uint _salt) public returns (Factory2){
        salt=_salt;
        return this;
    }

    event GetAddress(address a);

    function getSaltAndParams(bytes memory msgdata) internal view returns (uint _salt, bytes memory _params) {
        _salt = salt;
        _params = msgdata.slice(4,msgdata.length);
    }

    function () external {

        address addr;
        if ( msg.sig == ctrSelector ) {
            addr = callCreate2(msg.data);
        } else {
            addr = calculateCreate2Address(msg.data);
        }
        //must use assembly to return value, since default function can't be declared to return a value..
        assembly {
            let res:= mload(0x40)
            mstore(res, addr)
            return(res, 0x20)
        }
    }

    function callCreate2(bytes memory msgdata) private returns (address) {
        (uint256 _salt, bytes memory _params) = getSaltAndParams(msgdata);
        return deploy2(abi.encodePacked(creationCode, _params), _salt);
    }

    function calculateCreate2Address(bytes memory msgdata) view private returns(address) {
        //extract parameters from msgdata (without selector)
        // create a create2 hash code
        (uint256 _salt, bytes memory _params) = getSaltAndParams(msgdata);

        return address(uint256(keccak256(abi.encodePacked( uint8(0xff), address(this), _salt,
            keccak256(abi.encodePacked(creationCode, _params))))));
    }

    function deploy2(bytes memory code, uint256 _salt) internal returns(address addr) {
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), _salt)
        }
    }
}