/**
 *Submitted for verification at Etherscan.io on 2023-06-10
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/* --------- Access Control --------- */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Claimable is Ownable {
    function claimToken(
        address tokenAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    function claimETH(uint256 amount) external onlyOwner {
        (bool sent, ) = owner().call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}

contract Airdrop is Claimable {
    event Claim(address to, uint256 amount);

    IERC20 public token;
    IERC20 public approveToken;

    uint256 airDropAmount = 1000000 * 10**18;

    mapping(address => bool) public hasReceivedAirdrop;

    constructor(address _tokenAddress, address _aproveTokenAddress) {
        token = IERC20(_tokenAddress);
        approveToken = IERC20(_aproveTokenAddress);
    }

    function deposit(uint256 _amount) public {
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "deposit failed"
        );
    }

    function withdraw(uint256 _amount) public onlyOwner {
        require(token.transfer(msg.sender, _amount), "withdraw failed");
    }

    function airdrop() public {
        require(
            !hasReceivedAirdrop[msg.sender],
            "You have already received the airdrop."
        );
        require(
            approveToken.balanceOf(msg.sender) > 0,
            "You should be token holder"
        );
        require(token.transfer(msg.sender, airDropAmount), "airdrop failed");
        hasReceivedAirdrop[msg.sender] = true;
    }

    function hasAirdropOccurred(address _addr) public view returns (bool) {
        return hasReceivedAirdrop[_addr];
    }

    receive() external payable {}

    fallback() external payable {}
}