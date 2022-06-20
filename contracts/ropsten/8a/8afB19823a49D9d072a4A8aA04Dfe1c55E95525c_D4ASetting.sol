// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/ID4ASetting.sol";
import "./interface/ID4APRB.sol";
import "./interface/ID4AFeePoolFactory.sol";
import "./interface/ID4AERC20Factory.sol";
import "./interface/ID4AOwnerProxy.sol";
import "./interface/ID4AERC721Factory.sol";

contract D4ASetting is Ownable, ID4ASetting{

  constructor(){
  }

  event ChangeCreateFee(uint256 create_project_fee, uint256 create_canvas_fee);
  function changeCreateFee(uint256 _create_project_fee, uint256 _create_canvas_fee) public onlyOwner{
    create_project_fee = _create_project_fee;
    create_canvas_fee = _create_canvas_fee;
    emit ChangeCreateFee(create_project_fee, create_canvas_fee);
  }

  event ChangeProtocolFeePool(address addr);
  function changeProtocolFeePool(address addr) public onlyOwner{
    protocol_fee_pool = addr;
    emit ChangeProtocolFeePool(protocol_fee_pool);
  }

  event ChangeMintFeeRatio(uint256 d4a_ratio, uint256 project_ratio);
  function changeMintFeeRatio(uint256 _d4a_fee_ratio, uint256 _project_fee_ratio) public onlyOwner{
    mint_d4a_fee_ratio = _d4a_fee_ratio;
    mint_project_fee_ratio = _project_fee_ratio;
    emit ChangeMintFeeRatio(mint_d4a_fee_ratio, mint_project_fee_ratio);
  }

  event ChangeERC20TotalSupply(uint256 total_supply);
  function changeERC20TotalSupply(uint256 _total_supply) public onlyOwner{
    erc20_total_supply = _total_supply;
    emit ChangeERC20TotalSupply(erc20_total_supply);
  }

  event ChangeERC20Ratio(uint256 d4a_ratio, uint256 project_ratio, uint256 canvas_ratio);
  function changeERC20Ratio(uint256 _d4a_ratio, uint256 _project_ratio, uint256 _canvas_ratio) public onlyOwner{
    d4a_erc20_ratio = _d4a_ratio;
    project_erc20_ratio = _project_ratio;
    canvas_erc20_ratio = _canvas_ratio;
    require(_d4a_ratio + _project_ratio + _canvas_ratio == ratio_base, "invalid ratio");

    emit ChangeERC20Ratio(d4a_erc20_ratio, project_erc20_ratio, canvas_erc20_ratio);
  }

  event ChangeMaxMintableRounds(uint256 old_rounds, uint256 new_rounds);
  function changeMaxMintableRounds(uint256 _rounds) public onlyOwner{
    emit ChangeMaxMintableRounds(project_max_rounds, _rounds);
    project_max_rounds = _rounds;
  }

  event ChangeAddress(address PRB, address erc20_factory, address erc721_factory, address feepool_factory, address owner_proxy);
  function changeAddress(address _prb, address _erc20_factory,
                         address _erc721_factory,
                         address _feepool_factory,
                         address _owner_proxy) public onlyOwner{
    PRB = ID4APRB(_prb);
    erc20_factory = ID4AERC20Factory(_erc20_factory);
    erc721_factory = ID4AERC721Factory(_erc721_factory);
    feepool_factory = ID4AFeePoolFactory(_feepool_factory);
    owner_proxy = ID4AOwnerProxy(_owner_proxy);
    emit ChangeAddress(_prb, _erc20_factory, _erc721_factory, _feepool_factory, _owner_proxy);
  }

  event ChangeAssetPoolOwner(address new_owner);
  function changeAssetPoolOwner(address _owner) public onlyOwner{
    asset_pool_owner = _owner;
    emit ChangeAssetPoolOwner(_owner);
  }

  event ChangeFloorPrices(uint256[] prices);
  function changeFloorPrices(uint256[] memory _prices) public onlyOwner{
    delete floor_prices;
    floor_prices = _prices;
    emit ChangeFloorPrices(_prices);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;
import "./ID4APRB.sol";
import "./ID4AFeePoolFactory.sol";
import "./ID4AERC20Factory.sol";
import "./ID4AOwnerProxy.sol";
import "./ID4AERC721.sol";
import "./ID4AERC721Factory.sol";

contract ID4ASetting{
  uint256 public ratio_base;
  uint256 public min_stamp_duty; //TODO
  uint256 public max_stamp_duty;

  uint256 public create_project_fee;
  address public protocol_fee_pool;
  uint256 public create_canvas_fee;

  uint256 public mint_d4a_fee_ratio;
  uint256 public mint_project_fee_ratio;

  uint256 public erc20_total_supply;

  uint256 public project_max_rounds; //366

  uint256 public project_erc20_ratio;
  uint256 public canvas_erc20_ratio;
  uint256 public d4a_erc20_ratio;

  uint256[] public floor_prices;

  ID4APRB public PRB;

  string public erc20_name_prefix;
  string public erc20_symbol_prefix;

  ID4AERC721Factory public erc721_factory;
  ID4AERC20Factory public erc20_factory;
  ID4AFeePoolFactory public feepool_factory;
  ID4AOwnerProxy public owner_proxy;
  address public asset_pool_owner;

  constructor(){
    //some default value here
    ratio_base = 10000;
    create_project_fee = 1 ether;
    create_canvas_fee = 0.01 ether;
    mint_d4a_fee_ratio = 250;
    mint_project_fee_ratio = 3000;

    project_erc20_ratio = 300;
    d4a_erc20_ratio = 200;
    canvas_erc20_ratio = 9500;
    project_max_rounds = 366;
  }

  function floor_prices_length() public view returns(uint256){
    return floor_prices.length;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4APRB{
  function isStart() external view returns(bool);
  function currentRound() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AOwnerProxy{
  function ownerOf(bytes32 hash) external view returns(address);
  function initOwnerOf(bytes32 hash, address addr) external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AFeePoolFactory{
  function createD4AFeePool(string memory _name) external returns(address pool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AERC721Factory{
  function createD4AERC721(string memory _name, string memory _symbol) external returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AERC721{
  function mintItem(address player, string memory tokenURI) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AERC20Factory{
  function createD4AERC20(string memory _name, string memory _symbol, address _minter) external returns(address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}