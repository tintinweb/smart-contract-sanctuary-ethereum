pragma solidity ^0.8.0;

contract SaveData {
    string data = "hello";

    struct Blocks {
        int256 bnumber;
        string data;
    }

    Blocks[] public blocks;
    mapping(int256 => string) public bnumberToData;

    function store(string memory newdata) public {
        data = newdata;
    }

    function retrieve() public view returns (string memory) {
        return data;
    }

    function addData(int256 _bnumber, string memory _data) public {
        blocks.push(Blocks(_bnumber, _data));
        bnumberToData[_bnumber] = _data;
    }
}