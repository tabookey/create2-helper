pragma solidity ^0.5.8;

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

