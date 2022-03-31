pragma solidity ^0.8.0;

interface HalbornSeraph {
    function checkUnblocked(bytes4, bytes calldata, uint256) external;
}


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

}

contract Client {

    // TODO: Inline address without storage usage
    HalbornSeraph seraph_address;
    address owner;

    modifier withSeraph() {
        seraph_address.checkUnblocked(msg.sig, msg.data, 0);
        _;
    }

    modifier withSeraphPayable() {
        seraph_address.checkUnblocked(msg.sig, msg.data, msg.value);
        _;
    }

    constructor (){
    }

    //////  TESTING PURPOSE
    function devSetSeraph (address seraph) public{
        owner = msg.sender;
        seraph_address = HalbornSeraph(seraph);
    }
    //////  TESTING PURPOSE

    function emergencyWithdraw() external withSeraph() {

    }

    function emergencyWithdraw2(uint256 v) external withSeraph() {

    }

    function emergencyWithdraw3() external payable withSeraphPayable() {

    }

    function emergencyWithdraw4() external payable withSeraph() {

    }

}