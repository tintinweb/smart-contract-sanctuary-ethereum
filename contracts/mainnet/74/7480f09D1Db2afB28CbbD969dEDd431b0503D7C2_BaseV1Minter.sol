/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

library Math {
    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }
}

interface IGauges {
   function notifyRewardAmount(address token, uint amount) external;
}

interface ve {
    function token() external view returns (address);
    function totalSupply() external view returns (uint);
    function create_lock_for(uint, uint, address) external returns (uint);
    function transferFrom(address, address, uint) external;
}

interface underlying {
    function approve(address spender, uint value) external returns (bool);
    function mint(address, uint) external;
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function transfer(address, uint) external returns (bool);
    function setMinter(address _minter) external;
}

interface voter {
    function updateMinter(address) external;
    function notifyRewardAmount(uint amount) external;
}

interface ve_dist {
    function checkpoint_token() external;
    function checkpoint_total_supply() external;
    function setDepositor(address _depositor) external;
}

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

contract BaseV1Minter is Ownable {

    uint internal constant week = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
    uint internal constant emission = 98;
    uint internal constant tail_emission = 2;
    uint internal constant target_base = 100; // 2% per week target emission
    uint internal constant tail_base = 1000; // 0.2% per week target emission
    underlying public immutable _token;
    voter public immutable _voter;
    ve public immutable _ve;
    ve_dist public immutable _ve_dist;
    uint public weekly = 20000000e18;
    uint public active_period;
    uint internal constant lock = 86400 * 7 * 52 * 4;

    address internal initializer;
    address public fetch;

    address public gaugeDestributor;
    address public votersLock;
    address public operWallet;

    uint internal constant totalPercentReduce = 100000;
    uint public percentReduce = 14000;
    uint public operUnlockDate;

    bool public isMigrationLocked = false;

    event Mint(address indexed sender, uint weekly, uint circulating_supply, uint circulating_emission);

    constructor(
        address __voter, // the voting & distribution system
        address  __ve, // the ve(3,3) system that will be locked into
        address __ve_dist, // the distribution system that ensures users aren't diluted
        uint __operUnlockTime // UNIX time
    ) {
        initializer = msg.sender;
        _token = underlying(ve(__ve).token());
        _voter = voter(__voter);
        _ve = ve(__ve);
        _ve_dist = ve_dist(__ve_dist);
        active_period = (block.timestamp + (2*week)) / week * week;
        operUnlockDate = block.timestamp + __operUnlockTime;
    }

    function initialize(
      address _fetch,
      uint max,
      address _gaugeDestributor,
      address _votersLock,
      address _operWallet
    ) external {
        require(initializer == msg.sender);
        _token.mint(address(this), max);
        fetch = _fetch;
        initializer = address(0);
        active_period = (block.timestamp + week) / week * week;
        gaugeDestributor = _gaugeDestributor;
        votersLock = _votersLock;
        operWallet = _operWallet;
    }

    // allow mint for fetch
    function mintForFetch(uint _amount) external {
      require(msg.sender == fetch, "Not fetch");
      _token.mint(fetch, _amount);
      emit Mint(fetch, _amount, circulating_supply(), circulating_emission());
    }

    // calculate circulating supply as total token supply - locked supply
    function circulating_supply() public view returns (uint) {
        return _token.totalSupply() - _ve.totalSupply();
    }

    // emission calculation is 2% of available supply to mint adjusted by circulating / total supply
    function calculate_emission() public view returns (uint) {
        return weekly * emission * circulating_supply() / target_base / _token.totalSupply();
    }

    // weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
    function weekly_emission() public view returns (uint) {
        return _token.totalSupply() / totalPercentReduce * percentReduce; // Math.max(calculate_emission(), circulating_emission());
    }

    // calculates tail end (infinity) emissions as 0.2% of total supply
    function circulating_emission() public view returns (uint) {
        return circulating_supply() * tail_emission / tail_base;
    }

    // calculate inflation and adjust ve balances accordingly
    function calculate_growth(uint _minted) public view returns (uint) {
        return _ve.totalSupply() * _minted / _token.totalSupply();
    }


    // update period can only be called once per cycle (1 week)
    function update_period() external returns (uint) {
        uint _period = active_period;
        if (block.timestamp >= _period + week && initializer == address(0)) { // only trigger if new week

            if(percentReduce > 100){
              percentReduce -= (percentReduce / 100) * 2;
            }else{
              percentReduce = 0;
            }

            _period = block.timestamp / week * week;
            active_period = _period;
            weekly = weekly_emission();

            uint _growth = calculate_growth(weekly);
            uint _required = _growth + weekly;
            uint _balanceOf = _token.balanceOf(address(this));
            if (_balanceOf < _required) {
                _token.mint(address(this), _required-_balanceOf);
            }

            require(_token.transfer(address(_ve_dist), _growth));
            _ve_dist.checkpoint_token(); // checkpoint token balance that was just minted in ve_dist
            _ve_dist.checkpoint_total_supply(); // checkpoint supply

            // compute destribution
            uint operRewards = (weekly / 100) * 34;
            uint gaugeDestributorAmount = (weekly / 100) * 33;
            uint votersLockAmount = (weekly / 100) * 33;

            // 33% to platform pools
            _token.transfer(gaugeDestributor, gaugeDestributorAmount);

            // 33% to voters gauges locker
            _token.transfer(votersLock, votersLockAmount);

            // 34% bonus to oper wallet (burn if less than 6 month)
             address _oper = block.timestamp > operUnlockDate
             ? operWallet
             : address(0);

            _token.transfer(_oper, operRewards);

            emit Mint(msg.sender, weekly, circulating_supply(), circulating_emission());
        }
        return _period;
    }

    // allow owner update fetch
    function updateFetch(address _fetch) external onlyOwner {
      fetch = _fetch;
    }

    // allow migrate to new minter if issue will be with current
    function migrate(address _newMinter) external onlyOwner {
      require(!isMigrationLocked, "Migration locked");
      _token.setMinter(_newMinter);
      _ve_dist.setDepositor(_newMinter);
      _voter.updateMinter(_newMinter);
    }

    // allow owner lock migration for new minter forever 
    function lockMigrationForever() external onlyOwner {
      isMigrationLocked = true;
    }
}