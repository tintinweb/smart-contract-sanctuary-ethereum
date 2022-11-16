/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
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

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
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

    constructor() internal {
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
    function claimToken(address tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    function claimETH(uint256 amount) external onlyOwner {
        (bool sent, ) = owner().call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}

contract Presale is Claimable {
    event Buy(address to, uint256 amount);
    struct Terms {
        uint256 vestingPrice; //1e6
        uint256 vestingPeriod;
        uint256 price; //1e6
    }

    Terms public terms;
    address public tokenAddress;
    address adminWallet;

    uint256 public startTime;

    constructor(
        address _tokenAddress,
        address _adminWallet,
        Terms memory _terms
    ) public {
        tokenAddress = _tokenAddress;
        adminWallet = _adminWallet;
        terms = _terms;
        startTime = block.timestamp;
    }

    function resetTerms(Terms memory _terms) public onlyOwner {
        terms = _terms;
    }

    function setAdminWallet(address _adminWallet) external onlyOwner {
        adminWallet = _adminWallet;
    }

    function buy() public payable {
        uint256 tokenAmount = (msg.value * getPrice()) / 1e6;
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);

        (bool sent, ) = owner().call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        emit Buy(msg.sender, tokenAmount);
    }

    function getPrice() public view returns (uint256 tokenPrice) {
        tokenPrice = block.timestamp > terms.vestingPeriod
            ? terms.price
            : terms.vestingPrice;
    }

    receive() external payable {
        buy();
    }

    fallback() external payable {
        buy();
    }
}