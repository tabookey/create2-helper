//This file was auto-generated on Sun Nov 03 2019 13:55:52 GMT+0200 (Israel Standard Time)
//Source file: ./build/contracts/MyContract.json

pragma solidity ^0.5.8;

import "@tabookey/create2-helper/contracts/Factory2.sol";
import "./MyContract.sol";

/*
    Helper Factory to create class "MyContract" using create2
    For a given list of constructor param, getAddress will always return the same address.
    The create method will create the object at that same address, exactly once
    (and revert if called again)
    For more information, https://github.com/tabookey/create2-helper

USAGE: 

    IMyContractFactory factory = MyContractFactory.createFactory();
    address toBeCreated = factory.getAddress(_name);
    MyContract newObj = factory.create(_name);
    require( address(newObj) == toBeCreated );
 */

interface IMyContractFactory {
    
    function create(string calldata _name) external returns (MyContract);
    function getAddress(string calldata _name) view external returns (address);
    function setSalt(uint salt) external returns (IMyContractFactory);
}

library MyContractFactory {
    function createFactory() internal returns (IMyContractFactory) {
        return IMyContractFactory(address(new Factory2( type(MyContract).creationCode, IMyContractFactory(0).create.selector)));
    }
}
