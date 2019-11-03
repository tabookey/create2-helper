pragma solidity ^0.5.8;

//this is a sample contract
// it has some constructor parameters that define its state.
contract MyContract {
    string public name;
    uint public age;

    event Created(string name, uint age);

    constructor(string memory _name, uint _age) public {

        name = _name;
        age = _age;
        emit Created(name, age);
    }
}

