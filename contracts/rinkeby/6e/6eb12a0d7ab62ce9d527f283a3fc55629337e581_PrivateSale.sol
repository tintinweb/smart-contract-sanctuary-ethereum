/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PrivateSale is Ownable {
  IERC20 constant public pawth = IERC20(0x459BC05bF203cEd24E76c598B507aEAa9eD36C28);
  struct Sale {
    address buyer;
    uint256 ethAmt;
    uint256 tokenAmt;
    address token;
    bool sold;
    bool cancelled;
  }
  mapping(uint => Sale) public sales;
  uint public saleId = 0;

  constructor () {}

  function createSale (
    address _buyer, 
    uint256 _ethAmt, 
    uint256 _tokenAmt, 
    address _token
  ) external onlyOwner {
    sales[saleId] = Sale(
      _buyer,
      _ethAmt,
      _tokenAmt,
      _token,
      false,
      false
    );
    IERC20(_token).transferFrom(_msgSender(), address(this), _tokenAmt);
    saleId++;
  }

  function buyTokens (uint _saleId) payable external {
    Sale storage _sale = sales[_saleId];
    require(!_sale.sold, "Sale has been sold already");
    require(!_sale.cancelled, "Sale has been cancelled");
    require(_sale.buyer == _msgSender(), "You are not the buyer of this sale");
    require(_sale.ethAmt == msg.value, "Sale amount != Eth sent");

    _sale.sold = true;
    IERC20(_sale.token).transfer(_msgSender(), _sale.tokenAmt);
    payable(owner()).transfer(msg.value);
  }

  function cancelSale (uint _saleId) external onlyOwner {
    Sale storage _sale = sales[_saleId];
    require(!_sale.sold, "Sale has been sold already");
    require(!_sale.cancelled, "Sale has been cancelled already");
    _sale.cancelled = true;
    IERC20(_sale.token).transfer(owner(), _sale.tokenAmt);
  }

}