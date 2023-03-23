/**
 *Submitted for verification at Etherscan.io on 2023-03-23
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

contract MyContract {
    address private constant DAI_ADDRESS = 0xafB29BfF05Ec334f8BdB724Cd0BDDe0Df06729BE; // DAI token contract address
    IERC20 private dai = IERC20(DAI_ADDRESS);
    address public owner;

    mapping(address => uint256) public balanceOf;
    uint256 private _totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        owner = msg.sender;
    }

    modifier auth {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    function receiveDai(uint256 amount) external {
        require(dai.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }

    function getMyDaiBalance() external view returns (uint256) {
        return dai.balanceOf(address(this));
    }

    function mint(address usr, uint wad) external  auth {
        balanceOf[usr] += wad;
        _totalSupply += wad;
        emit Transfer(address(0), usr, wad);
    }

    function totalSupply() external view returns (uint256) {
        return dai.totalSupply();
    }
}