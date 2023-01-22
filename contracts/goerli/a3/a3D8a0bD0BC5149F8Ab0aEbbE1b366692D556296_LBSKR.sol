/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.17;

import "./Manageable.sol";
import "../openzeppelin/access/Ownable.sol";
import "../openzeppelin/security/Pausable.sol";
import "../openzeppelin/token/ERC20/IERC20.sol";
import "../uniswap/v2-core/interfaces/IUniswapV2Factory.sol";
import "../uniswap/v2-core/interfaces/IUniswapV2Pair.sol";
import "../uniswap/v2-periphery/interfaces/IUniswapV2Router02.sol";
import "../uniswap/v3-core/interfaces/IUniswapV3Factory.sol";
import "../uniswap/v3-core/interfaces/IUniswapV3Pool.sol";

abstract contract BaseBSKR is IERC20, Ownable, Manageable, Pausable {
    address private constant _DEXV2_ROUTER_ADDR =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // UniswapV2Router02
    address private constant _DEXV3_FACTORY_ADDR =
        0x1F98431c8aD98523631AE4a59f267346ea31F984; // UniswapV3Factory
    address private constant _DEXV3_ROUTER_ADDR =
        0xE592427A0AEce92De3Edee1F18E0157C05861564; // SwapRouter
    address private constant _NFPOSMAN_ADDR =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88; // NonfungiblePositionManager
    uint8 private constant _DECIMALS = 18;

    uint16 internal constant _BIPS = 10**4; // bips or basis point divisor
    // uint256 private constant _TOTAL_SUPPLY = (10 ** 12) * (10 ** _DECIMALS); // 1 trillion for PulseChain
    uint256 internal constant _TOTAL_SUPPLY = (10**9) * (10**_DECIMALS); // 1 billion for Goerli

    IUniswapV2Factory internal immutable _dexFactoryV2;
    IUniswapV2Router02 internal immutable _dexRouterV2;
    IUniswapV3Factory internal immutable _dexFactoryV3;
    address internal immutable _growthAddress; // 0x4F06FCcAa501B7BB9f9AFcEFb20f7862Be050B7d
    address internal _ammBSKRPair;
    address internal _ammLBSKRPair;

    address[] internal _sisterOAs;
    mapping(address => bool) internal _isAMMPair;
    mapping(address => bool) internal _paysNoFee;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) internal _balances;
    string private _name;
    string private _symbol;
    uint8 internal _oaIndex;

    event Log01B(string message);
    event Log02B(int24 tickSpacing);
    event LogBytesB(bytes data);

    constructor(
        string memory nameA,
        string memory symbolA,
        address growthAddressA,
        address[] memory sisterOAsA
    ) {
        _name = nameA;
        _symbol = symbolA;
        _growthAddress = growthAddressA;
        _sisterOAs = sisterOAsA;

        _dexRouterV2 = IUniswapV2Router02(_DEXV2_ROUTER_ADDR);
        _dexFactoryV2 = IUniswapV2Factory(_dexRouterV2.factory());

        _dexFactoryV3 = IUniswapV3Factory(_DEXV3_FACTORY_ADDR);

        // exclude owner and this contract from fee -- TODO do we need to add more?
        _paysNoFee[_msgSender()] = true;
        _paysNoFee[address(this)] = true;
        _paysNoFee[_DEXV2_ROUTER_ADDR] = true; // UniswapV2
        _paysNoFee[_DEXV3_ROUTER_ADDR] = true; // Uniswapv3 TODO do we need to add factories as well?
        _paysNoFee[_NFPOSMAN_ADDR] = true; // Uniswapv3
    }

    //to recieve ETH from _dexRouterV2 when swaping
    receive() external payable {}

    fallback() external payable {}

    /**
     * @notice Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "BSKR: From Zero Address");
        require(spender != address(0), "BSKR: To Zero Address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * TODO will we need this function?
     * Access to _approve for manager, so that approvals on behalf of contract may be performed
     */
    function _approveManager(
        address owner,
        address spender,
        uint256 amount
    ) external onlyManager {
        _approve(owner, spender, amount);
    }

    function _bytes32ToString(bytes32 x) private pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint256 charCount = 0;
        for (uint256 j = 0; j < 32; j++) {
            bytes1 char = x[j];
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    function _callAndParseInt24Return(address token, bytes4 selector)
        internal
        view
        returns (int24)
    {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(selector)
        );

        // if not implemented, or returns empty data, return empty string
        if (!success || data.length == 0) {
            return 0;
        }

        // if implemented, or returns data, return decoded int24 else return 0
        if (data.length == 32) {
            return abi.decode(data, (int24));
        }

        return 0;
    }

    function _callAndParseStringReturn(address token, bytes4 selector)
        private
        view
        returns (string memory)
    {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(selector)
        );

        // if not implemented, or returns empty data, return empty string
        if (!success || data.length == 0) {
            return "";
        }

        // bytes32 data always has length 32
        if (data.length == 32) {
            bytes32 decoded = abi.decode(data, (bytes32));
            return _bytes32ToString(decoded);
        } else if (data.length > 64) {
            return abi.decode(data, (string));
        }
        return "";
    }

    function _compare(string memory str1, string memory str2)
        private
        pure
        returns (bool)
    {
        if (bytes(str1).length != bytes(str2).length) {
            return false;
        }
        return
            keccak256(abi.encodePacked(str1)) ==
            keccak256(abi.encodePacked(str2));
    }

    function _getOriginAddress() internal returns (address) {
        if (_oaIndex < (_sisterOAs.length - 1)) {
            _oaIndex = _oaIndex + 1;
        } else {
            _oaIndex = 0;
        }
        return _sisterOAs[_oaIndex];
    }

    function _isUniswapV2Pair(address target) internal returns (bool) {
        // TODO can be set to view
        address token0;
        address token1;

        string memory targetSymbol = _callAndParseStringReturn(
            target,
            hex"95d89b41"
        );
        emit Log01B(targetSymbol);

        if (bytes(targetSymbol).length == 0) {
            return false;
        }

        if (_compare(targetSymbol, "UNI-V2")) {
            IUniswapV2Pair pairContract = IUniswapV2Pair(target);

            try pairContract.token0() returns (address _token0) {
                token0 = _token0;
            } catch Error(string memory reason) {
                //     // catch failing revert() and require()
                emit Log01B(reason);
                return false;
            } catch (bytes memory reason) {
                emit LogBytesB(reason);
                return false;
            }

            try pairContract.token1() returns (address _token1) {
                token1 = _token1;
            } catch Error(string memory reason) {
                // catch failing revert() and require()
                emit Log01B(reason);
                return false;
            } catch (bytes memory reason) {
                emit LogBytesB(reason);
                return false;
            }
        } else {
            return false;
        }

        return target == _dexFactoryV2.getPair(token0, token1);
    }

    function _isUniswapV3Pool(address target) private returns (bool) {
        // TODO can be set to view

        int24 targetTickSpacing = _callAndParseInt24Return(
            target,
            hex"d0c93a7c"
        );
        emit Log02B(targetTickSpacing);

        if (targetTickSpacing == 0) {
            return false;
        }

        address token0;
        address token1;
        uint24 fee;
        IUniswapV3Pool poolContract = IUniswapV3Pool(target);

        try poolContract.token0() returns (address _token0) {
            token0 = _token0;
        } catch (bytes memory) {
            return false;
        }

        try poolContract.token1() returns (address _token1) {
            token1 = _token1;
        } catch (bytes memory) {
            return false;
        }

        try poolContract.fee() returns (uint24 _fee) {
            fee = _fee;
        } catch (bytes memory) {
            return false;
        }

        return target == _dexFactoryV3.getPool(token0, token1, fee);
    }

    /**
     * @notice Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "BSKR: Insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transfer(
        address owner,
        address to,
        uint256 amount
    ) internal virtual;

    /**
     * @notice See {IERC20-allowance}.  TODO add description
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @notice See {IERC20-approve}. TODO add description
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @notice Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     */
    function decimals() public pure returns (uint8) {
        return _DECIMALS;
    }

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "BSKR: Decreases below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @notice Waives off fees for an address -- TODO probably we do not need this
     */
    // function excludeFromFee(address account) external onlyManager {
    //     _paysNoFee[account] = true;
    // }

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @notice Checks if an account is excluded from fees - TODO do we need this?
     */
    // function isExcludedFromFee(address account) external view returns (bool) {
    //     return _paysNoFee[account];
    // }

    /**
     * @notice Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @notice Pauses this contract features
     */
    function pauseContract() external onlyManager {
        _pause();
    }

    /**
     * @notice Returns the symbol of the token
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Returns the amount of tokens in existence.
     */
    function totalSupply() public pure override returns (uint256) {
        return _TOTAL_SUPPLY;
    }

    /**
     * @notice See {IERC20-transfer}.    TODO add description
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @notice See {IERC20-transferFrom}. TODO add description
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @notice Unpauses the contract's features
     */
    function unPauseContract() external onlyManager {
        _unpause();
    }
}

/*
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.17;

import "../openzeppelin/utils/Context.sol";

abstract contract Manageable is Context {
    address private _manager;
    event ManagementTransferred(
        address indexed previousManager,
        address indexed newManager
    );

    constructor() {
        address msgSender = _msgSender();
        _manager = msgSender;
        emit ManagementTransferred(address(0), msgSender);
    }

    function manager() public view returns (address) {
        return _manager;
    }

    modifier onlyManager() {
        require(_manager == _msgSender(), "Manageable: Caller not manager");
        _;
    }

    /**
     * @notice Transfers the management of the contract to a new manager
     */
    function transferManagement(address newManager) external onlyManager {
        emit ManagementTransferred(_manager, newManager);
        _manager = newManager;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../openzeppelin/access/Ownable.sol";

/**
 * @notice Stakable is a contract who is meant to be inherited by other contract that wants Staking capabilities
 */
contract Stakable is Ownable {
    /**
     * @notice Constructor since this contract is not ment to be used without inheritance
     * push once to _stakeholders for it to work proplerly
     */
    constructor() {
        // This push is needed so we avoid index 0 causing bug of index-1
        _stakeholders.push();
    }

    /**
     * @notice
     * A stake struct is used to represent the way we store stakes,
     * A Stake will contain the users address, the amount staked and a timestamp,
     * Since which is when the stake was made
     */
    struct Stake {
        address user; // TODO do we need this?
        uint256 amountLBSKR;
        uint256 amountBSKR;
        uint256 sharesLBSKR;
        uint256 sharesBSKR;
        uint256 sinceBlock;
    }
    /**
     * @notice Stakeholder is a staker that has active stakes
     */
    struct Stakeholder {
        address user;
        Stake[] userStakes;
    }

    // TODO use internal ones
    // uint256 internal _totalLBSKRStakes;
    // uint256 internal _totalBSKRStakes;
    // uint256 internal _totalLBSKRShares;
    // uint256 internal _totalBSKRShares;
    uint256 public _totalLBSKRStakes;
    uint256 public _totalBSKRStakes;
    uint256 public _totalLBSKRShares;
    uint256 public _totalBSKRShares;

    /**
     * @notice
     *   This is a array where we store all Stakes that are performed on the Contract
     *   The stakes for each address are stored at a certain index, the index can be found using the stakes mapping
     */
    // TODO use internal one
    // Stakeholder[] internal _stakeholders;
    Stakeholder[] public _stakeholders;

    /**
     * @notice
     * stakes is used to keep track of the INDEX for the stakers in the stakes array
     */
    // mapping(address => uint256) internal _stakes;
    mapping(address => uint256) public _stakes;

    /**
     * @notice Staked event is triggered whenever a user stakes tokens, address is indexed to make it filterable
     */
    event Staked(
        address indexed user,
        uint256 amountLBSKR,
        uint256 amountBSKR,
        uint256 sharesLBSKR,
        uint256 sharesBSKR,
        uint256 stakeIndex,
        uint256 sinceBlock
    );

    // TODO remove
    event Debug05L_(
        string msg,
        address user,
        uint256 amountLBSKR,
        uint256 amountBSKR,
        uint256 sharesLBSKR,
        uint256 sharesBSKR,
        uint256 sinceBlock
    );

    /**
     * @notice Unstaked event is triggered whenever a user unstakes tokens, address is indexed to make it filterable
     */
    // event Unstaked( TODO to be implemented
    //     address indexed user,
    //     uint256 amountLBSKR,
    //     uint256 amountBSKR,
    //     uint256 sharesLBSKR,
    //     uint256 sharesBSKR,
    //     uint256 StakeIndex,
    //     uint256 sinceBlock
    // );

    // ---------- STAKES ----------

    /**
     * @notice _addStakeholder takes care of adding a stakeholder to the _stakeholders array
     */
    function _addStakeholder(address staker) internal returns (uint256) {
        // Push a empty item to the Array to make space for our new stakeholder
        _stakeholders.push();
        // Calculate the index of the last item in the array by Len-1
        uint256 userIndex = _stakeholders.length - 1;
        // Assign the address to the new index
        _stakeholders[userIndex].user = staker;
        // Add index to the _stakeholders
        _stakes[staker] = userIndex;
        return userIndex;
    }

    /**
     * @notice
     * _Stake is used to make a stake for an sender. It will remove the amount staked from the stakers account and place those tokens inside a stake container
     * StakeID
     */
    function _stake(
        uint256 amountLBSKR,
        uint256 amountBSKR,
        uint256 sharesLBSKR,
        uint256 sharesBSKR // uint256 _rewardPerMonth
    ) internal {
        // Simple check so that user does not stake 0
        require(amountLBSKR > 0, "Cannot stake nothing");

        // Mappings in solidity creates all values, but empty, so we can just check the address
        uint256 userIndex = _stakes[_msgSender()];
        // block.timestamp = timestamp of the current block in seconds since the epoch
        uint256 sinceBlock = block.timestamp;
        // See if the staker already has a staked index or if its the first time
        if (userIndex == 0) {
            // This stakeholder stakes for the first time
            // We need to add him to the _stakeholders and also map it into the Index of the stakes
            // The index returned will be the index of the stakeholder in the _stakeholders array
            userIndex = _addStakeholder(_msgSender());
        }

        // uint256 timeToDistribute = sinceBlock + _untilBlock;

        // Use the index to push a new Stake
        // push a newly created Stake with the current block timestamp.

        //     Stake {
        //     address user; // TODO do we need this?
        //     uint256 amountLBSKR;
        //     uint256 amountBSKR;
        //     uint256 sharesLBSKR;
        //     uint256 sharesBSKR;
        //     uint256 sinceBlock;
        // }
        _stakeholders[userIndex].userStakes.push(
            Stake(
                _msgSender(),
                amountLBSKR,
                amountBSKR,
                sharesLBSKR,
                sharesBSKR,
                sinceBlock
            )
        );
        // Emit an event that the stake has occured
        emit Staked(
            _msgSender(),
            amountLBSKR,
            amountBSKR,
            sharesLBSKR,
            sharesBSKR,
            _stakeholders[userIndex].userStakes.length - 1,
            sinceBlock
        );
    }

    /**
     * @notice
     * withdrawStake takes in an amount and a index of the stake and will remove tokens from that stake
     * Notice index of the stake is the users stake counter, starting at 0 for the first stake
     * Will return the amount to MINT onto the acount
     * Will also calculateStakeReward and reset timer
     */
    function _withdrawStake(uint256 stakeIndex, uint256 stakeAmount)
        internal
        returns (
            Stake memory currStake,
            uint256 lbskrShares2Deduct,
            uint256 bskrShares2Deduct
        )
    {
        uint256 userIndex = _stakes[_msgSender()];
        require(
            stakeIndex < _stakeholders[userIndex].userStakes.length,
            "LBSKR: Stake index incorrect!"
        );

        // Stake memory
        currStake = _stakeholders[userIndex].userStakes[stakeIndex];

        emit Debug05L_(
            "before",
            _msgSender(),
            currStake.amountLBSKR,
            currStake.amountBSKR,
            currStake.sharesLBSKR,
            currStake.sharesBSKR,
            currStake.sinceBlock
        );

        require(
            currStake.amountLBSKR >= stakeAmount,
            "Staking: Cannot withdraw more than you have staked"
        );

        // uint256 lbskrStkRatio = (currStake.amountLBSKR) /
        //     currStake.sharesLBSKR;
        // uint256 bskrStkRatio = (currStake.amountBSKR) /
        //     currStake.sharesBSKR;
        // uint256 lbskrCurrRatio = (balanceOf(address(this)) +
        //     _totalLBSKRStakes) / _totalLBSKRShares;
        // uint256 bskrCurrRatio = (_BSKR.balanceOf(_inflationAddress)) /
        //     _totalBSKRShares;

        // Remove by subtracting the money unstaked
        // Same fraction of shares to be deducted from both BSKR and LBSKR
        // uint256
        lbskrShares2Deduct =
            (stakeAmount * currStake.sharesLBSKR) /
            currStake.amountLBSKR;
        uint256 bskrAmount2Deduct = (stakeAmount * currStake.amountBSKR) /
            currStake.amountLBSKR;
        // uint256
        bskrShares2Deduct =
            (stakeAmount * currStake.sharesBSKR) /
            currStake.amountLBSKR;

        // If stake is empty, 0, then remove it from the array of stakes
        if ((currStake.amountLBSKR - stakeAmount) == 0) {
            delete _stakeholders[userIndex].userStakes[stakeIndex];
        } else {
            // If not empty then replace the value of it
            _stakeholders[userIndex]
                .userStakes[stakeIndex]
                .amountLBSKR -= stakeAmount;
            _stakeholders[userIndex]
                .userStakes[stakeIndex]
                .amountBSKR -= bskrAmount2Deduct;
            _stakeholders[userIndex]
                .userStakes[stakeIndex]
                .sharesLBSKR -= lbskrShares2Deduct;
            _stakeholders[userIndex]
                .userStakes[stakeIndex]
                .sharesBSKR -= bskrShares2Deduct;
            // Reset timer of stake TODO do we need this? may be we burn delta rewards
            // _stakeholders[userIndex].userStakes[stakeIndex].sinceBlock = block
            //     .timestamp;

            emit Debug05L_(
                "after",
                _msgSender(),
                _stakeholders[userIndex].userStakes[stakeIndex].amountLBSKR,
                _stakeholders[userIndex].userStakes[stakeIndex].amountBSKR,
                _stakeholders[userIndex].userStakes[stakeIndex].sharesLBSKR,
                _stakeholders[userIndex].userStakes[stakeIndex].sharesBSKR,
                _stakeholders[userIndex].userStakes[stakeIndex].sinceBlock
            );
        }

        return (currStake, lbskrShares2Deduct, bskrShares2Deduct);
    }

    /**
     * @notice
     * hasStake is used to check if a account has stakes and the total amount along with all the seperate stakes
     */
    function hasStake(address _staker) public {
        Stake[] memory allStakes = _stakeholders[_stakes[_staker]].userStakes;

        // Iterate all stakes and grab amount of stakes
        for (uint256 s = 0; s < allStakes.length; s += 1) {
            emit Debug05L_(
                "---",
                _msgSender(),
                allStakes[s].amountLBSKR,
                allStakes[s].amountBSKR,
                allStakes[s].sharesLBSKR,
                allStakes[s].sharesBSKR,
                allStakes[s].sinceBlock
            );
        }
    }

    // @dev timestamp of the current block in seconds since the epoch
    // function getTime() public view returns (uint256 time) {
    //     return block.timestamp;
    // }

    /**
     * @notice Returns the total number of stake holders
     */
    function getTotalStakeholders() external view returns (uint256) {
        return _stakeholders.length;
    }

    /**
     * @notice A method to the aggregated stakes from all _stakeholders.
     * @return uint256 The aggregated stakes from all _stakeholders.
     */
    function getTotalStakes() external view returns (uint256) {
        uint256 __totalStakes = 0;
        for (uint256 s = 0; s < _stakeholders.length; s += 1) {
            __totalStakes = __totalStakes + _stakeholders[s].userStakes.length;
        }

        return __totalStakes;
    }

    /**
     * @notice Returns the stakes of a stakeholder
     */
    function stakesOf(address stakeholder)
        external
        view
        returns (Stake[] memory userStakes)
    {
        uint256 userIndex = _stakes[stakeholder];
        return _stakeholders[userIndex].userStakes;
    }

    /**
     * @notice Returns the shares of a stakeholder
     * TODO may not be needed if stakesOf works well
     */
    function sharesOf(address stakeholder)
        external
        view
        returns (Stake[] memory userStakes)
    {
        uint256 userIndex = _stakes[stakeholder];
        return _stakeholders[userIndex].userStakes;
    }
}

/**
 *
 * @title BSKR - Brings Serenity, Knowledge and Richness
 * @author Ra Murd <[email protected]>
 * @notice website: https://pulselorian.com/
 * @notice telegram: https://t.me/ThePulselorian
 * @notice twitter: https://twitter.com/ThePulseLorian
 *
 * BSKR is our attempt to develop a better internet currency
 * It's deflationary, burns some fees, reflects some fees and adds some fees to liquidity pool
 * It may also pay quarterly bonus to net buyers
 *
 * - BSKR audit
 *      <TODO Audit report link to be added here>
 *
 *
 *    (   (  (  (     (   (( (   .  (   (    (( (   ((
 *    )\  )\ )\ )\    )\ (\())\   . )\  )\   ))\)\  ))\
 *   ((_)((_)(_)(_)  ((_))(_)(_)   ((_)((_)(((_)_()((_)))
 *   | _ \ | | | |  / __| __| |   / _ \| _ \_ _|   \ \| |
 *   |  _/ |_| | |__\__ \ _|| |__| (_) |   /| || - | .  |
 *   |_|  \___/|____|___/___|____|\___/|_|_\___|_|_|_|\_|
 *
 * Tokenomics:
 *
 * Reflection       2.0%      36.36%
 * Burn             1.5%      27.27%
 * Growth           1.0%      18.18%
 * Liquidity        0.5%       9.09%
 * Payday           0.5%       9.09%
 */

/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.17;

import "./abstract/BaseBSKR.sol";
import "./abstract/Stakable.sol";
import "./lib/DSMath.sol";
import "./openzeppelin/utils/structs/EnumerableSet.sol";

// Uniswap addresses in play
// UniswapV2Pair: dynamic, created on demand for a pair
// UniswapV2Router02: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
// SwapRouter: 0xE592427A0AEce92De3Edee1F18E0157C05861564
// UniswapV2Factory: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
// UniswapV3Factory: 0x1F98431c8aD98523631AE4a59f267346ea31F984
// SwapRouter02: 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45 // TODO do we special treatment for this?
// NonfungiblePositionManager: 0xC36442b4a4522E871399CD717aBDD847Ab11FE88
// WETH9: 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6

// TODO add restriction to _inflationVaultAddress such that only this contract can withdraw
// TODO Recalculate the Token allocations to sacrificers
// TODO - adding liquidity is adding some to growth address
// TODO penality of 12% (reducing by a percent per month)
// TODO make all variabes private

// TODO evaluate each of these for our needs
// Stake function refundLockedBSKR(uint256 from, uint256 to) external onlyManager { TODO
// Stake function removeLockedRewards() external onlyManager { TODO do we need this?
// Stake function rewardForBSKR(address stakeholder, uint256 bskrAmount)
contract LBSKR is BaseBSKR, DSMath, Stakable {
    using EnumerableSet for EnumerableSet.AddressSet;

    enum Field {
        tTransferAmount,
        tBurnFee,
        tGrowthFee
    }

    // struct Stake {
    //     uint256 stakedBSKR;
    //     uint256 shares;
    // }
    // uint256 private constant _INF_RATE_DAILY = 0x33B5896A56042D2D5000000; // ray (10E27 precision) value for 1.0002 (1 + 0.02%)
    uint256 private constant _INF_RATE_HRLY = 0x33B2FEE4E1DEE6BDD000000; // ray (10E27 precision) value for 1.000008 (1 + 0.0008%)
    // uint8 private constant _INFLATION_BIPS = 2; // 0.02% of inflation vault balance
    uint16 private constant _SECS_IN_AN_HOUR = 3600;
    uint32 private constant _SECS_IN_FOUR_WEEKS = 2419200; // 3600 * 24 * 7 * 4

    IERC20 private _BSKR;
    address private immutable _inflationAddress; // 0x4F06FCcAa501B7BB9f9AFcEFb20f7862Be050B7d

    // EnumerableSet.AddressSet private _stakeholders;
    address private _BSKRAddr;
    bool private _initialRatioFlag;
    // mapping(address => Stake) private _stakeholderToStake;
    uint16 private _burnFee = 10; // 0.1% burn fee
    uint16 private _growthFee = 10; // 0.1% growth fee

    uint256 private _lastDistTS;
    // uint256 private _totalShares; // BSKR shares
    // uint256 private _totalStakes; // BSKR stakes

    // TODO remove debug events
    event Debug01L(
        address from,
        address to,
        string isFromPair,
        string isToPair,
        uint256 transferAmount,
        bool doTakeFee,
        bool fromNoFee,
        bool toNoFee
    );

    event Log02L(int24 tickSpacing);
    event Log03L(string name, uint256 value);
    event Debug02L(
        uint256 nowTS,
        uint256 inflation,
        uint256 balInf,
        uint256 balContract,
        uint256 infStartTS
    );

    event Debug03L(
        uint256 stakeAmount,
        uint256 shares,
        uint256 balInfAddrBefore,
        uint256 balInfAddrAfter,
        uint256 balInfDiff,
        uint256 totalStakedLBSKR,
        uint256 totalStakedBSKR,
        uint256 totalShares
    );
    event Debug04L(uint256 lbskrSent, uint256 bskrSent, uint256 penaltyFactor);
    event Debug05L(
        string msg,
        address user,
        uint256 amountLBSKR,
        uint256 amountBSKR,
        uint256 sharesLBSKR,
        uint256 sharesBSKR,
        uint256 sinceBlock
    );

    event Debug06L(
        uint256 amountLBSKR,
        uint256 amountBSKR,
        uint256 sharesLBSKR,
        uint256 sharesBSKR
    );

    // event StakeAdded(
    //     address indexed stakeholder,
    //     uint256 amount,
    //     uint256 shares,
    //     uint256 timestamp
    // );
    // event StakeRemoved(
    //     address indexed stakeholder,
    //     uint256 amount,
    //     uint256 shares,
    //     uint256 reward,
    //     uint256 timestamp
    // );

    event PairFoundL(address pair);
    event IsAPairL(string, address pair);
    event IsNotAPairL(string, address pair);

    event AmountsL(
        uint256 tTransferAmount,
        uint256 tBurnFee,
        uint256 tGrowthFee
    );

    modifier isInitialRatioNotSet() {
        require(!_initialRatioFlag, "LBSKR: Initial ratio set");
        _;
    }

    modifier isInitialRatioSet() {
        require(_initialRatioFlag, "LBSKR: Initial ratio not set");
        _;
    }

    // modifier inflationStarted() {
    //     require(_lastDistTS != 0, "LBSKR: Inflation not started yet");
    //     _;
    // }

    constructor(
        string memory nameA,
        string memory symbolA,
        address growthAddressA,
        address inflationAddressA,
        address[] memory sisterOAsA
    ) BaseBSKR(nameA, symbolA, growthAddressA, sisterOAsA) {
        _inflationAddress = address(inflationAddressA); // TODO may be this should be a contract for security
        // TODO pre-distribute all allocations as per tokenomics
        _balances[_msgSender()] = _TOTAL_SUPPLY / 2;
        emit Transfer(address(0), _msgSender(), _TOTAL_SUPPLY / 2);

        _balances[_inflationAddress] = _TOTAL_SUPPLY / 2;
        emit Transfer(address(0), address(this), _TOTAL_SUPPLY / 2);

        _ammLBSKRPair = _dexFactoryV2.createPair(
            address(this),
            _dexRouterV2.WETH()
        );
        _approve(_ammLBSKRPair, _ammLBSKRPair, type(uint256).max);
        _isAMMPair[_ammLBSKRPair] = true;

        for (uint8 i = 0; i < _sisterOAs.length; i++) {
            _paysNoFee[_sisterOAs[i]] = true;
        }

        // bskrERC20 = IERC20(_BSKRAddr); // TODO cannot set at the time of construction
        // bskrERC20 = this; // TODO remove - this is just for testing
    }

    /**
     * Airdrop BSKR to sacrificers, deducted from owner's wallet
     */
    function _airdropTransfer(address account, uint256 amount) private {
        _transferTokens(owner(), account, amount, false);
    }

    function _calcInflation(uint256 nowTS)
        private
        view
        returns (uint256 inflation)
    {
        require(_lastDistTS > 0, "Inflation not yet started!");
        // Always count seconds at beginning of the hour
        // uint256 secsElapsed = (nowTS - _lastDistTS); // miners can manipulate upto 900 secs
        uint256 hoursElapsed = uint256(
            (nowTS - _lastDistTS) / _SECS_IN_AN_HOUR
        );

        uint256 currBal = _balances[_inflationAddress];
        inflation = 0;
        if (hoursElapsed > 0) {
            uint256 infFracRay = rpow(_INF_RATE_HRLY, hoursElapsed);
            inflation = (currBal * infFracRay) / RAY - currBal;
        }

        // emit Debug02L(
        //     nowTS,
        //     inflation,
        //     _balances[_inflationAddress],
        //     _balances[address(this)],
        //     _lastDistTS
        // );

        return inflation;
    }

    function _checkIfAMMPair(address target) private {
        if (target.code.length == 0) return;
        if (!_isAMMPair[target]) {
            emit IsNotAPairL("Is not a pair", target);
            // if (_isUniswapV2Pair(target) || _isUniswapV3Pool(target)) { // TODO to be enabled later
            if (_isUniswapV2Pair(target)) {
                // TODO add support for V3 pool
                _isAMMPair[target] = true;
                emit PairFoundL(target);
            }
        } else {
            emit IsAPairL("Is a pair", target);
        }
    }

    function _creditInflation() public isInitialRatioSet {
        // TODO change to private
        // Always count seconds at beginning of the hour
        uint256 nowTS = block.timestamp - (block.timestamp % _SECS_IN_AN_HOUR);
        if (nowTS > _lastDistTS) {
            uint256 inflation = _calcInflation(nowTS);

            if (inflation > 0) {
                _lastDistTS = nowTS;
                _balances[_inflationAddress] -= inflation;
                _balances[address(this)] += inflation;
            }
        }
    }

    // function _creditInflation(uint256 inflation, uint256 nowTS) private {
    //     _lastDistTS = nowTS - (nowTS % _SECS_IN_AN_HOUR); // Always count seconds at beginning of the hour
    //     _balances[_inflationAddress] -= inflation;
    //     _balances[address(this)] += inflation;

    //     emit Debug02L(
    //         inflation,
    //         nowTS,
    //         _balances[_inflationAddress],
    //         _balances[address(this)],
    //         _lastDistTS
    //     );
    // }

    function _getValues(uint256 tAmount, bool takeFee)
        private
        view
        returns (uint256[] memory)
    {
        uint256[] memory response = new uint256[](3);

        if (!takeFee) {
            response[uint8(Field.tBurnFee)] = 0;
            response[uint8(Field.tGrowthFee)] = 0;
            response[uint8(Field.tTransferAmount)] = tAmount;
        } else {
            response[uint8(Field.tBurnFee)] = (tAmount * _burnFee) / _BIPS;
            response[uint8(Field.tGrowthFee)] = (tAmount * _growthFee) / _BIPS;
            response[uint8(Field.tTransferAmount)] =
                tAmount -
                response[uint8(Field.tBurnFee)] -
                response[uint8(Field.tGrowthFee)];
            // ((tAmount * _grossFees) / _BIPS);
        }

        // emit AmountsL(response[0], response[1], response[2]);

        return (response);
    }

    // Inflation starts at the start of the hour after enabled
    function _startInflation() private {
        // _lastDistTS =
        //     block.timestamp +
        //     (3600 - (block.timestamp % _SECS_IN_AN_HOUR));

        _lastDistTS = block.timestamp - (block.timestamp % _SECS_IN_AN_HOUR);

        emit Log03L("Inflation start time", _lastDistTS);
    }

    // TODO this function to be used in staking to add acquired BSKR
    function _swapTokensForTokens(address owner, uint256 tokenAmount)
        private
        returns (uint256 bskrAmount)
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _BSKRAddr;

        emit Debug02L(tokenAmount, 0, 0, 0, 0);
        _approve(owner, owner, tokenAmount); // allow owner to spend his/her tokens
        _approve(owner, address(_dexRouterV2), tokenAmount); // allow router to spend owner's tokens

        uint256 balInfAddrBefore = _BSKR.balanceOf(_inflationAddress);

        // make the swap
        _dexRouterV2.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            // address(this),
            _inflationAddress,
            block.timestamp + 15
        );

        // uint256 balInfAddrAfter = _BSKR.balanceOf(_inflationAddress);

        return _BSKR.balanceOf(_inflationAddress) - balInfAddrBefore;
    }

    function _takeFee(address target, uint256 tFee) private {
        _balances[target] += tFee;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "LBSKR: From Zero Address");
        require(to != address(0), "LBSKR: To Zero Address");
        require(amount > 0, "LBSKR: Zero transfer amount");

        // emit Log01L("About to call _checkIfAMMPair for from & to");
        _checkIfAMMPair(from);
        _checkIfAMMPair(to);
        // emit Log01L("Called _checkIfAMMPair for both from & to");

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _paysNoFee account then remove the fee
        if (_paysNoFee[from] || _paysNoFee[to]) {
            takeFee = false;
        }

        if (_isAMMPair[from] && !_isAMMPair[to]) {
            // Buy transaction
            emit Debug01L(
                from,
                to,
                "from is a pair",
                "to is a not pair",
                amount,
                takeFee,
                _paysNoFee[from],
                _paysNoFee[to]
            );
        } else if (!_isAMMPair[from] && _isAMMPair[to]) {
            // Sell transaction
            emit Debug01L(
                from,
                to,
                "from is a not pair",
                "to is a pair",
                amount,
                takeFee,
                _paysNoFee[from],
                _paysNoFee[to]
            );
        } else if (_isAMMPair[from] && _isAMMPair[to]) {
            // Hop between pools?
            // hop between LPs - avoiding double tax
            takeFee = false;
            emit Debug01L(
                from,
                to,
                "from is a pair",
                "to is a pair",
                amount,
                takeFee,
                _paysNoFee[from],
                _paysNoFee[to]
            );
        } else {
            // simple transfer not buy/sell

            emit Debug01L(
                from,
                to,
                "from is not a pair",
                "to is not a pair",
                amount,
                takeFee,
                _paysNoFee[from],
                _paysNoFee[to]
            );

            takeFee = false;
        }

        // Works for uniswap v3
        // if (to == _NFPOSMAN_ADDR) {
        //     _approve(from, _NFPOSMAN_ADDR, amount); // Allow nfPosMan to spend from's tokens
        //     // revert("UniswapV3 is not supported!");
        // }

        // TODO For testing purposes - approving all transfers
        // _approve(from, to, amount);

        //transfer amount, it will take tax, burn, liquidity fee
        _transferTokens(from, to, amount, takeFee);
    }

    function _transferTokens(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        uint256[] memory response = _getValues(tAmount, takeFee);

        _balances[sender] -= tAmount;
        _balances[recipient] += response[uint8(Field.tTransferAmount)];

        if (response[uint8(Field.tBurnFee)] > 0) {
            _takeFee(address(0), response[uint8(Field.tBurnFee)]);
            emit Transfer(sender, address(0), response[uint8(Field.tBurnFee)]);
        }

        if (response[uint8(Field.tGrowthFee)] > 0) {
            _takeFee(_growthAddress, response[uint8(Field.tGrowthFee)]);
            // TODO not emitting transfer event to minimize events in a transaction
            emit Transfer(
                sender,
                _growthAddress,
                response[uint8(Field.tGrowthFee)]
            );
        }

        emit Transfer(
            sender,
            recipient,
            response[uint8(Field.tTransferAmount)]
        );
    }

    /**
     * @notice See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Create a new stake
     * wallet (owner) needs LBSKR allowance for itself (spender)
     * also maybe LBSKR (spender) needs LSBKR allowance for wallet (owner)
     */
    function stake(uint256 amountLBSKR)
        external
        whenNotPaused
        isInitialRatioSet
    {
        require(amountLBSKR > 0, "LBSKR: Cannot stake nothing");
        // require(_BSKRAddr != address(0), "LBSKR: BSKR address not set");

        _creditInflation();
        // NAV value -> (_totalLBSKRStakes + balanceOf(address(this))) / _totalLBSKRShares
        // Divide the amountLBSKR by NAV
        uint256 sharesLBSKR = (amountLBSKR * _totalLBSKRShares) /
            (_totalLBSKRStakes + balanceOf(address(this)));

        _balances[_msgSender()] -= amountLBSKR;
        _balances[address(this)] += amountLBSKR;
        uint256 amountBSKR = _swapTokensForTokens(address(this), amountLBSKR);
        uint256 sharesBSKR = (amountBSKR * _totalBSKRShares) /
            (_BSKR.balanceOf(_inflationAddress));

        emit Debug06L(amountLBSKR, amountBSKR, sharesLBSKR, sharesBSKR);

        _stake(amountLBSKR, amountBSKR, sharesLBSKR, sharesBSKR); // For the first stake, the number of shares is the same as the amount

        _totalLBSKRStakes += amountLBSKR;
        _totalBSKRStakes += amountBSKR;
        _totalLBSKRShares += sharesLBSKR;
        _totalBSKRShares += sharesBSKR;
    }

    /**
     * @notice Returns the registered BSKR contract address
     * TODO do we need this function?
     */
    function getBSKRAddress() external view returns (address) {
        return _BSKRAddr;
    }

    /**
     * @notice Returns the amount of BSKR per share
     * TODO need to decide if we want to keep this function
     */
    // TODO sort
    function getBSKRPerShare()
        external
        view
        isInitialRatioSet
        returns (uint256)
    {
        // require(_BSKRAddr != address(0), "LBSKR: BSKR address not set");

        // if (_lastDistTS == 0) {
        //     return 0;
        // }

        return _BSKR.balanceOf(_inflationAddress) / _totalBSKRShares;
    }

    /**
     * @notice Returns the amount of LBSKR per share
     * TODO need to decide if we want to keep this function
     */
    // TODO sort
    function getLBSKRPerShare()
        external
        view
        isInitialRatioSet
        returns (
            // TODO need similar for BSKR as well
            uint256 lbskrPerShare
        )
    {
        // if (_lastDistTS == 0) {
        //     return 0;
        // }

        // TODO add penalty calculation with an bool argument
        uint256 inflation = _calcInflation(block.timestamp);
        return (balanceOf(address(this)) + inflation) / _totalLBSKRShares;
    }

    /**
     * @notice Returns the current accumulated LBSKR rewards
     */
    function getCurrentBalances()
        external
        view
        isInitialRatioSet
        returns (uint256 lbskrBalance, uint256 bskrBalance)
    {
        // require(_BSKRAddr != address(0), "LBSKR: BSKR address not set");

        // if (_lastDistTS == 0) {
        //     return (0, 0);
        // }

        // return bskrERC20.balanceOf(address(this)) - _totalStakes; // TODO _totalStakes is BSKR and balance is LBSKR
        uint256 inflation = _calcInflation(block.timestamp);
        return (
            (balanceOf(address(this)) + inflation),
            (_BSKR.balanceOf(_inflationAddress))
        );
    }

    /**
     * @notice Returns the total number of shares
     * TODO do we need this function?
     */
    function getTotalLBSKRShares() external view returns (uint256) {
        return _totalLBSKRShares;
    }

    /**
     * @notice Returns the total number of shares
     * TODO do we need this function?
     */
    function getTotalBSKRShares() external view returns (uint256) {
        return _totalBSKRShares;
    }

    /**
     * @notice Makes an account responsible for fees --  TODO do we need this?
     */
    // function includeInFee(address account) public onlyManager {
    //     _paysNoFee[account] = false;
    // }

    // TODO needs _BSKRAddr be set before use, revert?
    function isBSKRLBSKRV3Pool(address target) private returns (bool) {
        //if (target == _ammBSKRPair || target == _ammLBSKRPair) return false; // TODO this hasn't worked yet

        // TODO can be set to view
        address token0 = address(this);
        address token1 = _BSKRAddr;

        int24 targetTickSpacing = _callAndParseInt24Return(
            target,
            hex"d0c93a7c"
        );
        emit Log02L(targetTickSpacing);

        if (targetTickSpacing == 0) {
            return false;
        }

        IUniswapV3Pool poolContract = IUniswapV3Pool(target);

        uint24 fee;

        if (_BSKRAddr < address(this)) {
            token0 = _BSKRAddr;
            token1 = address(this);
        }

        try poolContract.fee() returns (uint24 _fee) {
            fee = _fee;
        } catch (bytes memory) {
            return false;
        }

        return target == _dexFactoryV3.getPool(token0, token1, fee);
    }

    /**
     * @notice Refunds the locked BSKR
     */
    // function refundLockedBSKR(uint256 from, uint256 to) external onlyManager {
    //     // IT - Invalid `to` param
    //     require(to <= _stakeholders.length(), "LBSKR: Invalid recipient");
    //     _creditInflation();
    //     uint256 s;

    //     for (s = from; s < to; s += 1) {
    //         _totalStakes -= _stakeholderToStake[_stakeholders.at(s)]
    //             .stakedBSKR;

    //         // T - BSKR transfer failed
    //         // _approve(
    //         //     _msgSender(),
    //         //     _msgSender(),
    //         //     _stakeholderToStake[_stakeholders.at(s)].stakedLBSKR
    //         // );
    //         // _approve(
    //         //     _msgSender(),
    //         //     address(this),
    //         //     _stakeholderToStake[_stakeholders.at(s)].stakedLBSKR
    //         // );
    //         // _approve(
    //         //     address(this),
    //         //     _msgSender(),
    //         //     _stakeholderToStake[_stakeholders.at(s)].stakedLBSKR
    //         // );
    //         // _approve(
    //         //     address(this),
    //         //     address(this),
    //         //     _stakeholderToStake[_stakeholders.at(s)].stakedLBSKR
    //         // );
    //         require(
    //             // bskrERC20.transfer(
    //             transfer(
    //                 _stakeholders.at(s),
    //                 _stakeholderToStake[_stakeholders.at(s)].stakedBSKR
    //             ),
    //             "LBSKR: TransferFrom failed"
    //         );

    //         _stakeholderToStake[_stakeholders.at(s)].stakedBSKR = 0;
    //     }
    // }

    /**
     * @notice Removes the locked rewards
     */
    // function removeLockedRewards() external onlyManager {
    //     // HS - _stakeholders still have stakes
    //     require(_totalStakes == 0, "LBSKR: Stakes exist");
    //     _creditInflation();
    //     // uint256 balance = bskrERC20.balanceOf(address(this));
    //     uint256 balance = balanceOf(address(this));

    //     require(
    //         // bskrERC20.transfer(_msgSender(), balance),
    //         // T - BSKR transfer failed
    //         transfer(_msgSender(), balance),
    //         "TF3"
    //     );
    // }

    /**
     * @notice Removes an existing stake (unstake)
     */
    function unstake(uint256 stakeAmount, uint256 stakeIndex)
        external
        isInitialRatioSet
        whenNotPaused
    {
        // require(_BSKRAddr != address(0), "LBSKR: BSKR address not set");

        _creditInflation();

        (
            Stake memory currStake,
            uint256 lbskrShares2Deduct,
            uint256 bskrShares2Deduct
        ) = _withdrawStake(stakeIndex, stakeAmount);

        uint256 lbskrCurrRatio = (balanceOf(address(this)) +
            _totalLBSKRStakes) / _totalLBSKRShares;
        uint256 bskrCurrRatio = (_BSKR.balanceOf(_inflationAddress)) /
            _totalBSKRShares;

        uint256 penaltyFactor = _BIPS;
        if (_lastDistTS + 52 weeks > block.timestamp) {
            uint256 fourWeeksElapsed = uint256(
                (block.timestamp - currStake.sinceBlock) / _SECS_IN_FOUR_WEEKS
            );
            if (fourWeeksElapsed < 13)
                penaltyFactor -= (_BIPS - ((13 - fourWeeksElapsed) * 100)); // If one four-weeks have elapsed - penalty is 12% or 1200/10000
        }

        uint256 lbskrToSend = ((lbskrCurrRatio *
            lbskrShares2Deduct -
            stakeAmount) * penaltyFactor) / _BIPS; // stakeAmount never existed - it's notional
        if (penaltyFactor < _BIPS) {
            uint256 lbskrToBurn = ((lbskrCurrRatio *
                lbskrShares2Deduct -
                stakeAmount) * (_BIPS - penaltyFactor)) / _BIPS;
            _balances[address(this)] -= lbskrToBurn;
            _balances[address(0)] += lbskrToBurn;

            emit Transfer(address(this), address(0), lbskrToBurn);
        }

        uint256 bskrToSend = (bskrCurrRatio *
            bskrShares2Deduct *
            penaltyFactor) / _BIPS;

        if (lbskrToSend > 0)
            require(
                transfer(_msgSender(), lbskrToSend),
                "LBSKR: LBSKR transfer failed"
            );

        if (bskrToSend > 0)
            require(
                _BSKR.transfer(_msgSender(), bskrToSend),
                "LBSKR: BSKR transfer failed"
            );

        emit Debug04L(lbskrToSend, bskrToSend, penaltyFactor);
    }

    /**
     * @notice Calculates reward for BSKR
     */
    // function rewardForBSKR(address stakeholder, uint256 bskrAmount)
    //     external
    //     returns (
    //         // view TODO enable later
    //         uint256
    //     )
    // {
    //     uint256 inflation = 0;

    //     if (_lastDistTS > 0) {
    //         inflation = _calcInflation(block.timestamp);
    //     }
    //     uint256 stakeholderStake = _stakeholderToStake[stakeholder].stakedBSKR;
    //     uint256 stakeholderShares = _stakeholderToStake[stakeholder].shares;

    //     // NS - Not enough staked!
    //     require(stakeholderStake >= bskrAmount, "LBSKR: Stake low");

    //     uint256 stakedRatio = (stakeholderStake) / stakeholderShares;
    //     // uint256 currentRatio = (bskrERC20.balanceOf(address(this))) /
    //     uint256 currentRatio = (balanceOf(address(this)) + inflation) /
    //         _totalShares;
    //     uint256 sharesToWithdraw = (bskrAmount * stakeholderShares) /
    //         stakeholderStake;

    //     if (currentRatio <= stakedRatio) {
    //         return 0;
    //     }

    //     uint256 rewards = (sharesToWithdraw * (currentRatio - stakedRatio));

    //     return rewards;
    // }

    /**
     * @notice Calculates rewards for a stakeholder
     */
    function rewardOf(address stakeholder, uint256 stakeIndex)
        external
        view
        returns (
            uint256 lbskrRewards,
            uint256 bskrRewards,
            uint256 penaltyFactor
        )
    {
        uint256 inflation = 0;
        if (_lastDistTS > 0) {
            inflation = _calcInflation(block.timestamp);
        }

        uint256 userIndex = _stakes[stakeholder];
        require(
            stakeIndex < _stakeholders[userIndex].userStakes.length,
            "LBSKR: Stake index incorrect!"
        );

        Stake memory currStake = _stakeholders[userIndex].userStakes[
            stakeIndex
        ];

        // uint256 lbskrStkRatio = (currStake.amountLBSKR) / currStake.sharesLBSKR;
        // uint256 bskrStkRatio = (currStake.amountBSKR) / currStake.sharesBSKR;

        // Remove by subtracting the money unstaked
        // Same fraction of shares to be deducted from both BSKR and LBSKR

        // If stake is empty, 0, then remove it from the array of stakes

        uint256 lbskrCurrRatio = (balanceOf(address(this)) +
            _totalLBSKRStakes) / _totalLBSKRShares;
        uint256 bskrCurrRatio = (_BSKR.balanceOf(_inflationAddress)) /
            _totalBSKRShares;

        penaltyFactor = _BIPS;
        if (_lastDistTS + 52 weeks > block.timestamp) {
            uint256 fourWeeksElapsed = uint256(
                (block.timestamp - currStake.sinceBlock) / _SECS_IN_FOUR_WEEKS
            );
            if (fourWeeksElapsed < 13)
                penaltyFactor -= (_BIPS - ((13 - fourWeeksElapsed) * 100)); // If one four weeks have elapsed - penalty is 12% or 1200/10000
        }

        lbskrRewards =
            (((lbskrCurrRatio * currStake.sharesLBSKR) -
                currStake.amountLBSKR) * penaltyFactor) /
            _BIPS; // stakeAmount never existed - it's notional
        bskrRewards =
            (((bskrCurrRatio * currStake.sharesBSKR) - currStake.amountBSKR) *
                penaltyFactor) /
            _BIPS;

        return (lbskrRewards, bskrRewards, penaltyFactor);
    }

    // Set the BSKR contract address
    // TODO sort
    function _setBSKRAddress(address newBSKRAddr) private {
        _BSKRAddr = newBSKRAddr;
        _BSKR = IERC20(_BSKRAddr);
        _ammBSKRPair = _dexFactoryV2.getPair(address(this), _BSKRAddr);

        if (_ammBSKRPair == address(0)) {
            _ammBSKRPair = _dexFactoryV2.createPair(address(this), _BSKRAddr);
        }

        _approve(_ammBSKRPair, _ammBSKRPair, type(uint256).max);
        _isAMMPair[_ammBSKRPair] = true;
    }

    // TODO eliminate this function and initialize automatically in constructor
    /**
     * @notice Set's the initial shares to stakes ratio and initializes
     * wallet (owner) needs LBSKR allowance for itself (spender)
     */
    function setInitialRatio(address newBSKRAddr, uint256 amountLBSKR)
        external
        onlyManager
        isInitialRatioNotSet
    {
        _setBSKRAddress(newBSKRAddr);

        require(
            _totalLBSKRShares == 0 && balanceOf(address(this)) == 0,
            "LBSKR: Non-zero balance"
        );

        // _approve(_msgSender(), _msgSender(), amountLBSKR);
        // uint256 amountBSKR = _swapTokensForTokens(_msgSender(), amountLBSKR);
        _balances[_msgSender()] -= amountLBSKR;
        _balances[address(this)] += amountLBSKR;

        uint256 amountBSKR = _swapTokensForTokens(address(this), amountLBSKR);

        _stake(amountLBSKR, amountBSKR, amountLBSKR, amountBSKR); // For the first stake, the number of shares is the same as the amount

        _totalLBSKRStakes = amountLBSKR;
        _totalBSKRStakes = amountBSKR;
        _totalLBSKRShares = amountLBSKR;
        _totalBSKRShares = amountBSKR;

        _initialRatioFlag = true;

        _startInflation();
    }

    /**
     * @notice Sets max transaction size for LBSKR - TODO we are not limiting LBSKR?
     */
    // function setMaxTxPercent(uint16 maxTxBips) external onlyManager {
    //     maxTxAmount = (_TOTAL_SUPPLY * maxTxBips) / _BIPS;
    // }

    // TODO  to be removed just for testing!
    // LBSKR (owner) needs LBSKR allowance for itself (spender)
    //
    function swapTokensForTokensExt(uint256 tokenAmount) external onlyManager {
        _swapTokensForTokens(_msgSender(), tokenAmount);
    }

    // TODO remove this test function
    function testCalcInflation(uint256 nowTS)
        external
        view
        onlyManager
        returns (uint256 inflation)
    {
        return _calcInflation(nowTS);
    }
}

/*
 * SPDX-License-Identifier: MIT
 */

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.17;

contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    // function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    //     require((z = x - y) <= x, "ds-math-sub-underflow");
    // }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    // function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
    //     return x <= y ? x : y;
    // }

    // function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
    //     return x >= y ? x : y;
    // }

    // function imin(int256 x, int256 y) internal pure returns (int256 z) {
    //     return x <= y ? x : y;
    // }

    // function imax(int256 x, int256 y) internal pure returns (int256 z) {
    //     return x >= y ? x : y;
    // }

    // uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    //rounds to zero if x*y < WAD / 2
    // function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    //     z = add(mul(x, y), WAD / 2) / WAD;
    // }

    //rounds to zero if x*y < WAD / 2
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    //rounds to zero if x*y < WAD / 2
    // function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
    //     z = add(mul(x, WAD), y / 2) / y;
    // }

    //rounds to zero if x*y < RAY / 2
    // function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
    //     z = add(mul(x, RAY), y / 2) / y;
    // }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.17;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "CNO");
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
        require(newOwner != address(0), "NOZA");
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.17;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: Paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: Not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.17;

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.17;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function allPairsLength() external view returns (uint);
    function allPairs(uint) external view returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import './pool/IUniswapV3PoolImmutables.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);
}