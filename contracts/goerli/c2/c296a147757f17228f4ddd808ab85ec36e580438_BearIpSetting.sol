// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IBearIpSetting.sol";

contract BearIpSetting is Ownable, IBearIpSetting {
    constructor() {}


  event ChangeCreateFee(uint256 create_project_fee);
  function changeCreateFee(uint256 _create_box_fee) public onlyOwner{
    create_box_fee = _create_box_fee;
    emit ChangeCreateFee(create_box_fee);
  }


  event ChangeServiceFeeRatio(uint256 service_bi_fee_ratio);
  function changeServiceFeeRatio(uint256 _service_bi_fee_ratio) public onlyOwner{
    service_bi_fee_ratio = _service_bi_fee_ratio;
    emit ChangeServiceFeeRatio(service_bi_fee_ratio);
  }

    event ChangeAddress(address owner_proxy);
  function changeAddress(address _owner_proxy) public onlyOwner{
   
    owner_proxy = IBearIpOwnerProxy(_owner_proxy);
    emit ChangeAddress( _owner_proxy);
  }


 event ChangeProtocolFeePool(address addr);
  function changeProtocolFeePool(address addr) public onlyOwner{
    protocol_fee_pool = addr;
    emit ChangeProtocolFeePool(protocol_fee_pool);
  }

   event ChangeNFT721Vault(address nft_721_vault);
  function changeNFT721Vault(address _nft_721_vault) public onlyOwner{
    nft_721_vault = _nft_721_vault;
    emit ChangeNFT721Vault(_nft_721_vault);
  }
 
 

  event ChangeDurationBlocks(uint256[] durations);
  function changeDurationBlocks(uint256[] memory _durations) public onlyOwner{
    delete duration_blocks;
    duration_blocks = _durations;
    emit ChangeDurationBlocks(_durations);
  }

    event ChangeGapBlocks(uint256[] durations);
  function changeGapBlocks(uint256[] memory _gaps) public onlyOwner{
    delete gap_blocks;
    gap_blocks = _gaps;
    emit ChangeGapBlocks(_gaps);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IBearIpOwnerProxy {
    
    function ownerOf(bytes32 hash) external view returns (address);

    function initOwnerOf(bytes32 hash, address addr) external returns (bool);

    function transferOwnership(bytes32 hash, address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./IBearIpOwnerProxy.sol";

contract IBearIpSetting {
    uint256 public ratio_base;

    uint256 public create_box_fee;
    address public protocol_fee_pool;

    address public nft_721_vault;

    uint256 public service_bi_fee_ratio;

    uint256[] public duration_blocks;
    uint256[] public gap_blocks;

    IBearIpOwnerProxy public owner_proxy;
     
    


    constructor() {
        //some default value here
        ratio_base = 10000;
        create_box_fee = 0.01 ether;
        service_bi_fee_ratio = 150;
        duration_blocks = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000];

        gap_blocks = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000];
    
    }
     function duration_blocks_length() public view returns(uint256){
    return duration_blocks.length;
  }
  function gap_blocks_length() public view returns(uint256){
    return gap_blocks.length;
  }

 
}