/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract CafeTokenPresale is Ownable {
    mapping(uint => uint) public tokenPrices;
    IERC20 public stableCoin;
    IERC1155 public cafeToken;

    // Public functions
    function buy(uint id, uint amount) public
    {
        require(tokenPrices[id] != 0, "Invalid price");
        uint totalPrice = amount * tokenPrices[id];
        stableCoin.transferFrom(msg.sender, address(this), totalPrice);
        cafeToken.safeTransferFrom(
            address(this),
            msg.sender,
            id,
            amount,
            "");
    }

    // Owner functions
    function setPrice(uint id, uint price) public onlyOwner
    {
        tokenPrices[id] = price;
    }

    function setStableCoin(address stableCoinAddress) public onlyOwner
    {
        stableCoin = IERC20(stableCoinAddress);
    }

    function setCafeToken(address cafeTokenAddress) public onlyOwner
    {
        cafeToken = IERC1155(cafeTokenAddress);
    }

    function withdraw() public onlyOwner
    {
        stableCoin.transfer(owner(), stableCoin.balanceOf(address(this)));
    }
}