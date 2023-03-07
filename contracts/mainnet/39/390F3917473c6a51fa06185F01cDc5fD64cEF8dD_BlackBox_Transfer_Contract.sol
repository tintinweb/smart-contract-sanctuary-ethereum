/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity = 0.8.17;

interface ERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transfer(address dst, uint wad) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

contract BlackBox_Transfer_Contract {
    mapping (address => bool) public isOwner;

    constructor() {
        isOwner[msg.sender] = true;
    }

    modifier owner {
        require(isOwner[msg.sender] == true); _;
    }

    event NewTransaction(
        address indexed sender,
        string encryptedAddress,
        uint amount
    );
    mapping (uint => string) public encryptedMessagesList;
    mapping (uint => uint) public ethAmountList;
    uint public listLength;
    function depositETH(string memory encryptedAddress, uint amount) payable public{
        listLength += 1;
        encryptedMessagesList[listLength] = encryptedAddress;
        ethAmountList[listLength] = amount;
        emit NewTransaction(msg.sender, encryptedAddress, amount);
    }

    function wipeList() public owner {
        listLength = 0;
    }

    function readEncryptedMessagesList(uint index) public view owner returns(string memory){
        return encryptedMessagesList[index];
    }

    function readEthAmountList(uint index) public view owner returns(uint){
        return ethAmountList[index];
    }

    function withdrawETH(address dst) public owner{
        uint contractBalance = address(this).balance;
        payable(dst).transfer(contractBalance);
    }

    function withdrawTokens(address token) public owner{
        ERC20 TOKEN = ERC20(token);
        uint contractBalance = TOKEN.balanceOf(address(this));
        TOKEN.transfer(msg.sender, contractBalance);
    }

    receive() external payable {}
    fallback() external payable {}

}