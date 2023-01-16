/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity = 0.8.17;

interface ERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transfer(address dst, uint wad) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}


contract BB_deposit_contract {
    mapping (address => bool) public isOwner;

    constructor() {
        isOwner[msg.sender] = true;
    }

    modifier owner {
        require(isOwner[msg.sender] == true); _;
    }

    mapping (uint => string) public encryptedMessagesList;
    mapping (uint => uint) public ethAmountList;
    uint public listLength;
    function depositETH(string memory encryptedAddress, uint amount) payable public{
        listLength += 1;
        encryptedMessagesList[listLength] = encryptedAddress;
        ethAmountList[listLength] = amount;
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

    function sendETHViaCall(address payable _to) public payable owner {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
    fallback() external payable {}

}