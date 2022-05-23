/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File contracts/dependencies/openzeppelin/contracts/Context.sol

// //-License-Identifier: MIT
pragma solidity 0.8.10;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}


// File contracts/dependencies/openzeppelin/contracts/Ownable.sol

// //-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


// File contracts/dependencies/openzeppelin/contracts/IERC20.sol

// //-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol

// //-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

interface IERC20Detailed is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}


// File contracts/dependencies/chainlink/AggregatorInterface.sol

// //-License-Identifier: MIT
// Chainlink Contracts v0.8
pragma solidity ^0.8.0;

interface AggregatorInterface {
    function decimals() external view returns (uint8);
    
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}


// File contracts/pcv/PCV.sol

// //-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;



interface IStakedToken {
    function stake(address to, uint256 amount) external;
}

contract PCV is Ownable {
    struct Bundle {
        address[] assets;
        uint8 allocation;
        uint256 totalSold;
    }

    struct Round {
        uint32 start;
        uint32 end;
        uint256 totalAvailableForSale;
        uint256 totalSold;
        uint256 sOMNIPrice;
        Bundle[] bundles;
        mapping(address => int8) assetIndexes;
    }

    mapping(uint8 => Round) public rounds;
    mapping(address => address) public priceAggregators;

    address public immutable sOMNI;
    address public immutable OMNI;
    uint8 public currentRound = 0;

    event Supply(
        address asset,
        uint256 amount,
        address from,
        uint256 sOMNIAmount
    );

    event Withdraw(address asset, uint256 amount, address to);

    constructor(address _sOMNI, address _OMNI) {
        sOMNI = _sOMNI;
        OMNI = _OMNI;
    }

    function startNewRound(
        uint256 totalAvailableForSale, //Amount of OMNI
        uint256 priceInUSD,
        uint32 currentRoundEndAt
    ) public onlyOwner {
        Round storage round = rounds[currentRound];
        require(round.end < block.timestamp, "previous round hasn't ended");
        round.sOMNIPrice = priceInUSD;
        round.totalAvailableForSale = totalAvailableForSale;
        round.totalSold = 0;
        round.start = uint32(block.timestamp);
        round.end = currentRoundEndAt;
        currentRound = currentRound + 1;
    }

    function setRoundEndDate(uint32 currentRoundEndAt) public onlyOwner {
        Round storage round = rounds[currentRound - 1];
        round.end = currentRoundEndAt;
    }

    function addPriceAggregators(
        address[] memory assets,
        address[] memory _priceAggregators
    ) public onlyOwner {
        for (uint256 i = 0; i < _priceAggregators.length; i = i + 1) {
            priceAggregators[assets[i]] = _priceAggregators[i];
        }
    }

    function addBundle(address[] memory assets, uint8 allocation)
        public
        onlyOwner
    {
        Round storage round = rounds[currentRound - 1];
        Bundle memory bundle = Bundle(assets, allocation, 0);
        round.bundles.push(bundle);

        for (uint8 i = 0; i < assets.length; i++) {
            round.assetIndexes[assets[i]] = int8(uint8(round.bundles.length));
        }
    }

    function supply(address asset, uint256 _amount) public payable {
        Round storage round = rounds[currentRound - 1];
        require(round.end > block.timestamp, "current round has ended");

        address priceAggregator = priceAggregators[asset];
        require(priceAggregator != address(0), "asset aggregator is missing");

        uint256 amount;
        if (asset == address(0)) {
            amount = msg.value;
        } else {
            amount = _amount;
        }

        int256 price = AggregatorInterface(priceAggregator).latestAnswer(); // Ex: 293066000000
        uint256 transferAmount;

        int8 bundleIndex = round.assetIndexes[asset] - 1;
        require(round.assetIndexes[asset] >= 0, "asset is not supported");

        if (asset != address(0)) {
            bool success = IERC20Detailed(asset).transferFrom(
                msg.sender,
                address(this),
                _amount
            );
            require(success == true, "unable to transfer asset");
            uint8 decimals = IERC20Detailed(asset).decimals();
            transferAmount =
                (amount * uint256(price) * (10**(18 - decimals))) /
                round.sOMNIPrice;
        } else {
            transferAmount = (amount * uint256(price)) / round.sOMNIPrice;
        }

        IERC20Detailed(OMNI).approve(sOMNI, transferAmount);
        IStakedToken(sOMNI).stake(msg.sender, transferAmount);

        round.totalSold = round.totalSold + transferAmount;
        require(
            round.totalSold <= round.totalAvailableForSale,
            "sale limit exceeded"
        );

        Bundle storage bundle = round.bundles[uint8(bundleIndex)];

        bundle.totalSold = bundle.totalSold + transferAmount;
        uint256 totalOMNIAllocated = (round.totalAvailableForSale *
            bundle.allocation) / 100;

        require(totalOMNIAllocated >= bundle.totalSold, "exceeds allocation");

        emit Supply(asset, amount, msg.sender, transferAmount);
    }

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) public onlyOwner {
        if (asset == address(0)) {
            (bool success, ) = to.call{value: amount}("");
            require(success == true, "unable to send ether");
        } else {
            bool success = IERC20Detailed(asset).transfer(to, amount);
            require(success == true, "unable to send asset");
        }

        emit Withdraw(asset, amount, to);
    }

    function getBundles(uint8 round) public view returns (Bundle[] memory) {
        return rounds[round - 1].bundles;
    }
}