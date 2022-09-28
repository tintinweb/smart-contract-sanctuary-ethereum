// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./BaseToken.sol";
import "./NewTransition.sol";
import "./interfaces/ITellorFlex.sol";

/**
 @author Tellor Inc.
 @title Tellor360
 @dev This is the controller contract which defines the functionality for
 * changing the oracle contract address, as well as minting and migrating tokens
*/
contract Tellor360 is BaseToken, NewTransition {
    // Events
    event NewOracleAddress(address _newOracle, uint256 _timestamp);
    event NewProposedOracleAddress(
        address _newProposedOracle,
        uint256 _timestamp
    );

    // Functions
    /**
     * @dev Constructor used to store new flex oracle address
     * @param _flexAddress is the new oracle contract which will replace the
     * tellorX oracle
     */
    constructor(address _flexAddress) {
        require(_flexAddress != address(0), "oracle address must be non-zero");
        addresses[keccak256("_ORACLE_CONTRACT_FOR_INIT")] = _flexAddress;
    }

    /**
     * @dev Use this function to initiate the contract
     */
    function init() external {
        require(uints[keccak256("_INIT")] == 0, "should only happen once");
        uints[keccak256("_INIT")] = 1;
        // retrieve new oracle address from Tellor360 contract address storage
        NewTransition _newController = NewTransition(
            addresses[_TELLOR_CONTRACT]
        );
        address _flexAddress = _newController.getAddressVars(
            keccak256("_ORACLE_CONTRACT_FOR_INIT")
        );
        //on switch over, require tellorFlex values are over 12 hours old
        //then when we switch, the governance switch can be instantaneous
        bytes32 _id = 0x83a7f3d48786ac2667503a61e8c415438ed2922eb86a2906e4ee66d9a2ce4992;
        uint256 _firstTimestamp = IOracle(_flexAddress)
            .getTimestampbyQueryIdandIndex(_id, 0);
        require(
            block.timestamp - _firstTimestamp >= 12 hours,
            "contract should be at least 12 hours old"
        );
        addresses[_ORACLE_CONTRACT] = _flexAddress; //used by Liquity+AMPL for this contract's reads
        //init minting uints (timestamps)
        uints[keccak256("_LAST_RELEASE_TIME_TEAM")] = block.timestamp;
        uints[keccak256("_LAST_RELEASE_TIME_DAO")] = block.timestamp - 12 weeks;
        // transfer dispute fees collected during transition period to team
        _doTransfer(
            addresses[_GOVERNANCE_CONTRACT],
            addresses[_OWNER],
            balanceOf(addresses[_GOVERNANCE_CONTRACT])
        );
    }

    /**
     * @dev Mints tokens of the sender from the old contract to the sender
     */
    function migrate() external {
        require(!migrated[msg.sender], "Already migrated");
        _doMint(
            msg.sender,
            BaseToken(addresses[_OLD_TELLOR]).balanceOf(msg.sender)
        );
        migrated[msg.sender] = true;
    }

    /**
     * @dev Use this function to withdraw released tokens to the oracle
     */
    function mintToOracle() external {
        require(uints[keccak256("_INIT")] == 1, "tellor360 not initiated");
        // X - 0.02X = 144 daily time based rewards. X = 146.94
        uint256 _releasedAmount = (146.94 ether *
            (block.timestamp - uints[keccak256("_LAST_RELEASE_TIME_DAO")])) /
            86400;
        uints[keccak256("_LAST_RELEASE_TIME_DAO")] = block.timestamp;
        uint256 _stakingRewards = (_releasedAmount * 2) / 100;
        _doMint(addresses[_ORACLE_CONTRACT], _releasedAmount - _stakingRewards);
        // Send staking rewards
        _doMint(address(this), _stakingRewards);
        _allowances[address(this)][
            addresses[_ORACLE_CONTRACT]
        ] = _stakingRewards;
        ITellorFlex(addresses[_ORACLE_CONTRACT]).addStakingRewards(
            _stakingRewards
        );
    }

    /**
     * @dev Use this function to withdraw released tokens to the team
     */
    function mintToTeam() external {
        require(uints[keccak256("_INIT")] == 1, "tellor360 not initiated");
        uint256 _releasedAmount = (146.94 ether *
            (block.timestamp - uints[keccak256("_LAST_RELEASE_TIME_TEAM")])) /
            (86400);
        uints[keccak256("_LAST_RELEASE_TIME_TEAM")] = block.timestamp;
        _doMint(addresses[_OWNER], _releasedAmount);
    }

    /**
     * @dev This function allows team to gain control of any tokens sent directly to this
     * contract (and send them back))
     */
    function transferOutOfContract() external {
        _doTransfer(address(this), addresses[_OWNER], balanceOf(address(this)));
    }

    /**
     * @dev Use this function to update the oracle contract
     */
    function updateOracleAddress() external {
        bytes32 _queryID = keccak256(
            abi.encode("TellorOracleAddress", abi.encode(bytes("")))
        );
        bytes memory _proposedOracleAddressBytes;
        (, _proposedOracleAddressBytes, ) = IOracle(addresses[_ORACLE_CONTRACT])
            .getDataBefore(_queryID, block.timestamp - 12 hours);
        address _proposedOracle = abi.decode(
            _proposedOracleAddressBytes,
            (address)
        );
        // If the oracle address being reported is the same as the proposed oracle then update the oracle contract
        // only if 7 days have passed since the new oracle address was made official
        // and if 12 hours have passed since query id 1 was first reported on the new oracle contract
        if (_proposedOracle == addresses[keccak256("_PROPOSED_ORACLE")]) {
            require(
                block.timestamp >
                    uints[keccak256("_TIME_PROPOSED_UPDATED")] + 7 days,
                "must wait 7 days after proposing new oracle"
            );
            bytes32 _id = 0x83a7f3d48786ac2667503a61e8c415438ed2922eb86a2906e4ee66d9a2ce4992;
            uint256 _firstTimestamp = IOracle(_proposedOracle)
                .getTimestampbyQueryIdandIndex(_id, 0);
            require(
                block.timestamp - _firstTimestamp >= 12 hours,
                "contract should be at least 12 hours old"
            );
            addresses[_ORACLE_CONTRACT] = _proposedOracle;
            emit NewOracleAddress(_proposedOracle, block.timestamp);
        }
        // Otherwise if the current reported oracle is not the proposed oracle, then propose it and
        // start the clock on the 7 days before it can be made official
        else {
            require(_isValid(_proposedOracle), "invalid oracle address");
            addresses[keccak256("_PROPOSED_ORACLE")] = _proposedOracle;
            uints[keccak256("_TIME_PROPOSED_UPDATED")] = block.timestamp;
            emit NewProposedOracleAddress(_proposedOracle, block.timestamp);
        }
    }

    /**
     * @dev Used during the upgrade process to verify valid Tellor Contracts
     */
    function verify() external pure returns (uint256) {
        return 9999;
    }

    /**Internal Functions */
    /**
     * @dev Used during the upgrade process to verify valid Tellor Contracts and ensure
     * they have the right signature
     * @param _contract is the address of the Tellor contract to verify
     * @return bool of whether or not the address is a valid Tellor contract
     */
    function _isValid(address _contract) internal returns (bool) {
        (bool _success, bytes memory _data) = address(_contract).call(
            abi.encodeWithSelector(0xfc735e99, "") // verify() signature
        );
        require(
            _success && abi.decode(_data, (uint256)) > 9000, // An arbitrary number to ensure that the contract is valid
            "New contract is invalid"
        );
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./oldContracts/contracts/TellorVars.sol";
import "./oldContracts/contracts/interfaces/IOracle.sol";
import "./oldContracts/contracts/tellor3/TellorStorage.sol";

/**
 @author Tellor Inc.
 @title NewTransition
* @dev The Transition contract links to the Oracle contract and
* allows parties (like Liquity) to continue to use the master
* address to access values which use legacy query IDs (request IDs). 
*/
contract NewTransition is TellorStorage, TellorVars {
    // Functions
    //Getters
    /**
     * @dev Allows Tellor to read data from the addressVars mapping
     * @param _data is the keccak256("_VARIABLE_NAME") of the variable that is being accessed.
     * These are examples of how the variables are saved within other functions:
     * addressVars[keccak256("_OWNER")]
     * addressVars[keccak256("_TELLOR_CONTRACT")]
     * @return address of the requested variable
     */
    function getAddressVars(bytes32 _data) external view returns (address) {
        return addresses[_data];
    }

    /**
     * @dev Returns the latest value for a specific request ID.
     * @param _requestId the requestId to look up
     * @return uint256 the latest value of the request ID
     * @return bool whether or not the value was successfully retrieved
     */
    function getLastNewValueById(uint256 _requestId)
        external
        view
        returns (uint256, bool)
    {
        uint256 _count = getNewValueCountbyRequestId(_requestId);
        if (_count == 0) {
            return (0, false);
        }
        uint256 _latestTimestamp = getTimestampbyRequestIDandIndex(
            _requestId,
            _count - 1
        );
        return (retrieveData(_requestId, _latestTimestamp), true);
    }

    /**
     * @dev Function is solely for the parachute contract
     */
    function getNewCurrentVariables()
        external
        view
        returns (
            bytes32 _c,
            uint256[5] memory _r,
            uint256 _diff,
            uint256 _tip
        )
    {
        _r = [uint256(1), uint256(1), uint256(1), uint256(1), uint256(1)];
        _diff = 0;
        _tip = 0;
        _c = keccak256(
            abi.encode(
                IOracle(addresses[_ORACLE_CONTRACT]).getTimeOfLastNewValue()
            )
        );
    }

    /**
     * @dev Counts the number of values that have been submitted for the requestId.
     * @param _requestId the requestId to look up
     * @return uint256 count of the number of values received for the requestId
     */
    function getNewValueCountbyRequestId(uint256 _requestId)
        public
        view
        returns (uint256)
    {
        (bytes32 _queryId, ) = _getQueryIdAndDecimals(_requestId);
        IOracle _oracle = IOracle(addresses[_ORACLE_CONTRACT]);
        // try the new oracle first
        try _oracle.getNewValueCountbyQueryId(_queryId) returns (
            uint256 _valueCount
        ) {
            if (_valueCount == 0) {
                return 0;
            }
            // if last value is disputed, subtract 1 from the count until a non-disputed value is found
            uint256 _timestamp = _oracle.getTimestampbyQueryIdandIndex(
                _queryId,
                _valueCount - 1
            );
            while (
                _oracle.isInDispute(_queryId, _timestamp) &&
                _valueCount > 1
            ) {
                _valueCount--;
                _timestamp = _oracle.getTimestampbyQueryIdandIndex(
                    _queryId,
                    _valueCount - 1
                );
            }
            if (
                _valueCount == 1 &&
                _oracle.isInDispute(_queryId, _timestamp)
            ) {
                return 0;
            }
            return _valueCount;
        } catch {
            return
                IOracle(addresses[_ORACLE_CONTRACT]).getTimestampCountById(
                    bytes32(_requestId)
                );
        }
    }

    /**
     * @dev Gets the timestamp for the value based on its index
     * @param _requestId is the requestId to look up
     * @param _index is the value index to look up
     * @return uint256 timestamp
     */
    function getTimestampbyRequestIDandIndex(uint256 _requestId, uint256 _index)
        public
        view
        returns (uint256)
    {
        (bytes32 _queryId, ) = _getQueryIdAndDecimals(_requestId);
        try
            IOracle(addresses[_ORACLE_CONTRACT]).getTimestampbyQueryIdandIndex(
                _queryId,
                _index
            )
        returns (uint256 _val) {
            if(_requestId == 1 && _val > block.timestamp - 15 minutes) {
                ( , , _val) = IOracle(addresses[_ORACLE_CONTRACT]).getDataBefore(_queryId, block.timestamp - 15 minutes);
            }
            return _val;
        } catch {
            return
                IOracle(addresses[_ORACLE_CONTRACT]).getReportTimestampByIndex(
                    bytes32(_requestId),
                    _index
                );
        }
    }

    /**
     * @dev Getter for the variables saved under the TellorStorageStruct uints variable
     * @param _data the variable to pull from the mapping. _data = keccak256("_VARIABLE_NAME")
     * where variable_name is the variables/strings used to save the data in the mapping.
     * The variables names in the TellorVariables contract
     * @return uint256 of specified variable
     */
    function getUintVar(bytes32 _data) external view returns (uint256) {
        return uints[_data];
    }

    /**
     * @dev Getter for if the party is migrated
     * @param _addy address of party
     * @return bool if the party is migrated
     */
    function isMigrated(address _addy) external view returns (bool) {
        return migrated[_addy];
    }

    /**
     * @dev Retrieve value from oracle based on timestamp
     * @param _requestId being requested
     * @param _timestamp to retrieve data/value from
     * @return uint256 value for timestamp submitted
     */
    function retrieveData(uint256 _requestId, uint256 _timestamp)
        public
        view
        returns (uint256)
    {
        (bytes32 _queryId, uint256 _decimalsAdjustment) = _getQueryIdAndDecimals(
            _requestId
        );
        try
            IOracle(addresses[_ORACLE_CONTRACT]).getValueByTimestamp(
                bytes32(_requestId),
                _timestamp
            )
        returns (bytes memory _val) {
            return _sliceUint(_val);
        } catch {
            bytes memory _val;
            if (_requestId == 1) {
                (, _val, ) = IOracle(addresses[_ORACLE_CONTRACT])
                    .getDataBefore(_queryId, block.timestamp - 15 minutes);
            } else {
                 _val = IOracle(addresses[_ORACLE_CONTRACT])
                .retrieveData(_queryId, _timestamp);
            }
            return (_sliceUint(_val) / (10**_decimalsAdjustment));
        }
    }



    // Internal functions
    /**
     * @dev Utilized to help slice a bytes variable into a uint
     * @param _b is the bytes variable to be sliced
     * @return _number of the sliced uint256
     */
    function _sliceUint(bytes memory _b)
        internal
        pure
        returns (uint256 _number)
    {
        for (uint256 _i = 0; _i < _b.length; _i++) {
            _number = _number * 2**8;
            _number = _number + uint8(_b[_i]);
        }
    }

    function _getQueryIdAndDecimals(uint256 _requestId) internal pure returns (bytes32, uint256) {
        bytes32 _queryId;
        uint256 _decimalsAdjustment;
        if(_requestId == 1) {
            _queryId = 0x83a7f3d48786ac2667503a61e8c415438ed2922eb86a2906e4ee66d9a2ce4992; // SpotPrice(eth, usd)
            _decimalsAdjustment = 12;
        } else if(_requestId == 10) {
            _queryId = 0x0d12ad49193163bbbeff4e6db8294ced23ff8605359fd666799d4e25a3aa0e3a; // AmpleforthCustomSpotPrice(0x)
            _decimalsAdjustment = 0;
        } else if(_requestId == 41) {
            _queryId = 0x612ec1d9cee860bb87deb6370ed0ae43345c9302c085c1dfc4c207cbec2970d7; // AmpleforthUSPCE(0x)
            _decimalsAdjustment = 0;
        } else {
            _queryId = bytes32(_requestId);
            _decimalsAdjustment = 0;
        }
        return(_queryId, _decimalsAdjustment);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./oldContracts/contracts/TellorVars.sol";
import "./oldContracts/contracts/interfaces/IGovernance.sol";
import "./oldContracts/contracts/tellor3/TellorStorage.sol";

/**
 @author Tellor Inc.
 @title BaseToken
 @dev Contains the methods related to ERC20 transfers, allowance, and storage
*/
contract BaseToken is TellorStorage, TellorVars {
    // Events
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    ); // ERC20 Approval event
    event Transfer(address indexed _from, address indexed _to, uint256 _value); // ERC20 Transfer Event

    // Functions
    /**
     * @dev This function approves a _spender an _amount of tokens to use
     * @param _spender address receiving the allowance
     * @param _amount amount the spender is being approved for
     * @return bool true if spender approved successfully
     */
    function approve(address _spender, uint256 _amount)
        external
        returns (bool)
    {
        require(_spender != address(0), "ERC20: approve to the zero address");
        _allowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @notice Allows tellor team to transfer stake of disputed TellorX reporter
     * NOTE: this does not affect TellorFlex stakes, only disputes during 360 transition period
     * @param _from the staker address holding the tokens being transferred
     * @param _to the address of the recipient
     */
    function teamTransferDisputedStake(address _from, address _to) external {
        require(
            msg.sender == addresses[_OWNER],
            "only owner can transfer disputed staked"
        );
        require(
            stakerDetails[_from].currentStatus == 3,
            "_from address not disputed"
        );
        stakerDetails[_from].currentStatus = 0;
        _doTransfer(_from, _to, uints[_STAKE_AMOUNT]);
    }

    /**
     * @dev Transfers _amount tokens from message sender to _to address
     * @param _to token recipient
     * @param _amount amount of tokens to send
     * @return success whether the transfer was successful
     */
    function transfer(address _to, uint256 _amount)
        external
        returns (bool success)
    {
        _doTransfer(msg.sender, _to, _amount);
        return true;
    }

    /**
     * @notice Send _amount tokens to _to from _from on the condition it
     * is approved by _from
     * @param _from the address holding the tokens being transferred
     * @param _to the address of the recipient
     * @param _amount the amount of tokens to be transferred
     * @return success whether the transfer was successful
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool success) {
        require(
            _allowances[_from][msg.sender] >= _amount,
            "Allowance is wrong"
        );
        _allowances[_from][msg.sender] -= _amount;
        _doTransfer(_from, _to, _amount);
        return true;
    }

    // Getters
    /**
     * @dev Getter function for remaining spender balance
     * @param _user address of party with the balance
     * @param _spender address of spender of said user's balance
     * @return uint256 the remaining allowance of tokens granted to the _spender from the _user
     */
    function allowance(address _user, address _spender)
        external
        view
        returns (uint256)
    {
        return _allowances[_user][_spender];
    }

    /**
     * @dev This function returns whether or not a given user is allowed to trade a given amount
     * and removes the staked amount if they are staked in TellorX and disputed
     * @param _user address of user
     * @param _amount to check if the user can spend
     * @return bool true if they are allowed to spend the amount being checked
     */
    function allowedToTrade(address _user, uint256 _amount)
        public
        view
        returns (bool)
    {
        if (stakerDetails[_user].currentStatus == 3) {
            // Subtracts the stakeAmount from balance if the _user is staked and disputed in TellorX
            return (balanceOf(_user) - uints[_STAKE_AMOUNT] >= _amount);
        }
        return (balanceOf(_user) >= _amount); // Else, check if balance is greater than amount they want to spend
    }

    /**
     * @dev Gets the balance of a given address
     * @param _user the address whose balance to look up
     * @return uint256 the balance of the given _user address
     */
    function balanceOf(address _user) public view returns (uint256) {
        return balanceOfAt(_user, block.number);
    }

    /**
     * @dev Gets the historic balance of a given _user address at a specific _blockNumber
     * @param _user the address whose balance to look up
     * @param _blockNumber the block number at which the balance is queried
     * @return uint256 the balance of the _user address at the _blockNumber specified
     */
    function balanceOfAt(address _user, uint256 _blockNumber)
        public
        view
        returns (uint256)
    {
        TellorStorage.Checkpoint[] storage checkpoints = balances[_user];
        if (
            checkpoints.length == 0 || checkpoints[0].fromBlock > _blockNumber
        ) {
            return 0;
        } else {
            if (_blockNumber >= checkpoints[checkpoints.length - 1].fromBlock)
                return checkpoints[checkpoints.length - 1].value;
            // Binary search of the value in the array
            uint256 _min = 0;
            uint256 _max = checkpoints.length - 2;
            while (_max > _min) {
                uint256 _mid = (_max + _min + 1) / 2;
                if (checkpoints[_mid].fromBlock == _blockNumber) {
                    return checkpoints[_mid].value;
                } else if (checkpoints[_mid].fromBlock < _blockNumber) {
                    _min = _mid;
                } else {
                    _max = _mid - 1;
                }
            }
            return checkpoints[_min].value;
        }
    }

    /**
     * @dev Allows users to access the number of decimals
     */
    function decimals() external pure returns (uint8) {
        return 18;
    }

    /**
     * @dev Allows users to access the token's name
     */
    function name() external pure returns (string memory) {
        return "Tellor Tributes";
    }

    /**
     * @dev Allows users to access the token's symbol
     */
    function symbol() external pure returns (string memory) {
        return "TRB";
    }

    /**
     * @dev Getter for the total_supply of tokens
     * @return uint256 total supply
     */
    function totalSupply() external view returns (uint256) {
        return uints[_TOTAL_SUPPLY];
    }

    // Internal functions
    /**
     * @dev Helps mint new TRB
     * @param _to is the address to send minted amount to
     * @param _amount is the amount of TRB to mint and send
     */
    function _doMint(address _to, uint256 _amount) internal {
        // Ensure to address and mint amount are valid
        require(_amount != 0, "Tried to mint non-positive amount");
        require(_to != address(0), "Receiver is 0 address");
        uint128 _previousBalance = uint128(balanceOf(_to));
        uint128 _sizedAmount = uint128(_amount);
        // Update total supply and balance of _to address
        uints[_TOTAL_SUPPLY] += _amount;
        _updateBalanceAtNow(_to, _previousBalance + _sizedAmount);
        emit Transfer(address(0), _to, _amount);
    }

    /**
     * @dev Completes transfers by updating the balances at the current block number
     * and ensuring the amount does not contain tokens locked for tellorX disputes
     * @param _from address to transfer from
     * @param _to address to transfer to
     * @param _amount amount of tokens to transfer
     */
    function _doTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            return;
        }
        require(
            allowedToTrade(_from, _amount),
            "Should have sufficient balance to trade"
        );
        // Update balance of _from address
        uint128 _previousBalance = uint128(balanceOf(_from));
        uint128 _sizedAmount = uint128(_amount);
        _updateBalanceAtNow(_from, _previousBalance - _sizedAmount);
        // Update balance of _to address
        _previousBalance = uint128(balanceOf(_to));
        _updateBalanceAtNow(_to, _previousBalance + _sizedAmount);
        emit Transfer(_from, _to, _amount);
    }

    /**
     * @dev Updates balance checkpoint _amount for a given _user address at the current block number
     * @param _user is the address whose balance to update
     * @param _value is the new balance
     */
    function _updateBalanceAtNow(address _user, uint128 _value) internal {
        Checkpoint[] storage checkpoints = balances[_user];
        // Checks if no checkpoints exist, or if checkpoint block is not current block
        if (
            checkpoints.length == 0 ||
            checkpoints[checkpoints.length - 1].fromBlock != block.number
        ) {
            // If yes, push a new checkpoint into the array
            checkpoints.push(
                TellorStorage.Checkpoint({
                    fromBlock: uint128(block.number),
                    value: _value
                })
            );
        } else {
            // Else, update old checkpoint
            TellorStorage.Checkpoint storage oldCheckPoint = checkpoints[
                checkpoints.length - 1
            ];
            oldCheckPoint.value = _value;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface ITellorFlex {
    function addStakingRewards(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./tellor3/TellorVariables.sol";

/**
 @author Tellor Inc.
 @title TellorVariables
 @dev Helper contract to store hashes of variables.
 * For each of the bytes32 constants, the values are equal to
 * keccak256([VARIABLE NAME])
*/
contract TellorVars is TellorVariables {
    // Storage
    address constant TELLOR_ADDRESS =
        0x88dF592F8eb5D7Bd38bFeF7dEb0fBc02cf3778a0; // Address of main Tellor Contract
    // Hashes for each pertinent contract
    bytes32 constant _GOVERNANCE_CONTRACT =
        0xefa19baa864049f50491093580c5433e97e8d5e41f8db1a61108b4fa44cacd93;
    bytes32 constant _ORACLE_CONTRACT =
        0xfa522e460446113e8fd353d7fa015625a68bc0369712213a42e006346440891e;
    bytes32 constant _TREASURY_CONTRACT =
        0x1436a1a60dca0ebb2be98547e57992a0fa082eb479e7576303cbd384e934f1fa;
    bytes32 constant _SWITCH_TIME =
        0x6c0e91a96227393eb6e42b88e9a99f7c5ebd588098b549c949baf27ac9509d8f;
    bytes32 constant _MINIMUM_DISPUTE_FEE =
        0x7335d16d7e7f6cb9f532376441907fe76aa2ea267285c82892601f4755ed15f0;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IOracle{
    function getReportTimestampByIndex(bytes32 _queryId, uint256 _index) external view returns(uint256);
    function getNewValueCountbyQueryId(bytes32 _queryId) external view returns(uint256);
    function getValueByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(bytes memory);
    function getBlockNumberByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(uint256);
    function getReporterByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(address);
    function getReporterLastTimestamp(address _reporter) external view returns(uint256);
    function reportingLock() external view returns(uint256);
    function removeValue(bytes32 _queryId, uint256 _timestamp) external;
    function getReportsSubmittedByAddress(address _reporter) external view returns(uint256);
    function getTipsByUser(address _user) external view returns(uint256);
    function tipQuery(bytes32 _queryId, uint256 _tip, bytes memory _queryData) external;
    function submitValue(bytes32 _queryId, bytes calldata _value, uint256 _nonce, bytes memory _queryData) external;
    function burnTips() external;
    function verify() external pure returns(uint);
    function changeReportingLock(uint256 _newReportingLock) external;
    function changeTimeBasedReward(uint256 _newTimeBasedReward) external;
    function getTipsById(bytes32 _queryId) external view returns(uint256);
    function getTimestampCountById(bytes32 _queryId) external view returns(uint256);
    function getTimestampIndexByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(uint256);
    function getCurrentValue(bytes32 _queryId) external view returns(bytes memory);
    function getTimeOfLastNewValue() external view returns(uint256);
    function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index) external view returns(uint256);
    function getDataBefore(bytes32 _queryId, uint256 _timestamp) external view returns(bool, bytes memory, uint256);
    function getTokenAddress() external view returns(address);
    function getStakeAmount() external view returns(uint256);
    function isInDispute(bytes32 _queryId, uint256 _timestamp) external view returns(bool);
    function slashReporter(address _reporter, address _recipient) external returns(uint256);
    function retrieveData(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bytes memory);
    function getStakerInfo(address _stakerAddress)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.4;

/**
  @author Tellor Inc.
  @title TellorStorage
  @dev Contains all the variables/structs used by Tellor
*/
contract TellorStorage {
    //Internal struct for use in proof-of-work submission
    struct Details {
        uint256 value;
        address miner;
    }
    struct Dispute {
        bytes32 hash; //unique hash of dispute: keccak256(_miner,_requestId,_timestamp)
        int256 tally; //current tally of votes for - against measure
        bool executed; //is the dispute settled
        bool disputeVotePassed; //did the vote pass?
        bool isPropFork; //true for fork proposal NEW
        address reportedMiner; //miner who submitted the 'bad value' will get disputeFee if dispute vote fails
        address reportingParty; //miner reporting the 'bad value'-pay disputeFee will get reportedMiner's stake if dispute vote passes
        address proposedForkAddress; //new fork address (if fork proposal)
        mapping(bytes32 => uint256) disputeUintVars;
        mapping(address => bool) voted; //mapping of address to whether or not they voted
    }
    struct StakeInfo {
        uint256 currentStatus; //0-not Staked, 1=Staked, 2=LockedForWithdraw 3= OnDispute 4=ReadyForUnlocking 5=Unlocked
        uint256 startDate; //stake start date
    }
    //Internal struct to allow balances to be queried by blocknumber for voting purposes
    struct Checkpoint {
        uint128 fromBlock; // fromBlock is the block number that the value was generated from
        uint128 value; // value is the amount of tokens at a specific block number
    }
    struct Request {
        uint256[] requestTimestamps; //array of all newValueTimestamps requested
        mapping(bytes32 => uint256) apiUintVars;
        mapping(uint256 => uint256) minedBlockNum; //[apiId][minedTimestamp]=>block.number
        //This the time series of finalValues stored by the contract where uint UNIX timestamp is mapped to value
        mapping(uint256 => uint256) finalValues;
        mapping(uint256 => bool) inDispute; //checks if API id is in dispute or finalized.
        mapping(uint256 => address[5]) minersByValue;
        mapping(uint256 => uint256[5]) valuesByTimestamp;
    }
    uint256[51] requestQ; //uint50 array of the top50 requests by payment amount
    uint256[] public newValueTimestamps; //array of all timestamps requested
    //This is a boolean that tells you if a given challenge has been completed by a given miner
    mapping(uint256 => uint256) requestIdByTimestamp; //minedTimestamp to apiId
    mapping(uint256 => uint256) requestIdByRequestQIndex; //link from payoutPoolIndex (position in payout pool array) to apiId
    mapping(uint256 => Dispute) public disputesById; //disputeId=> Dispute details
    mapping(bytes32 => uint256) public requestIdByQueryHash; // api bytes32 gets an id = to count of requests array
    mapping(bytes32 => uint256) public disputeIdByDisputeHash; //maps a hash to an ID for each dispute
    mapping(bytes32 => mapping(address => bool)) public minersByChallenge;
    Details[5] public currentMiners; //This struct is for organizing the five mined values to find the median
    mapping(address => StakeInfo) stakerDetails; //mapping from a persons address to their staking info
    mapping(uint256 => Request) requestDetails;
    mapping(bytes32 => uint256) public uints;
    mapping(bytes32 => address) public addresses;
    mapping(bytes32 => bytes32) public bytesVars;
    //ERC20 storage
    mapping(address => Checkpoint[]) public balances;
    mapping(address => mapping(address => uint256)) public _allowances;
    //Migration storage
    mapping(address => bool) public migrated;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.4;

/**
 @author Tellor Inc.
 @title TellorVariables
 @dev Helper contract to store hashes of variables
*/
contract TellorVariables {
    bytes32 constant _BLOCK_NUMBER =
        0x4b4cefd5ced7569ef0d091282b4bca9c52a034c56471a6061afd1bf307a2de7c; //keccak256("_BLOCK_NUMBER");
    bytes32 constant _CURRENT_CHALLENGE =
        0xd54702836c9d21d0727ffacc3e39f57c92b5ae0f50177e593bfb5ec66e3de280; //keccak256("_CURRENT_CHALLENGE");
    bytes32 constant _CURRENT_REQUESTID =
        0xf5126bb0ac211fbeeac2c0e89d4c02ac8cadb2da1cfb27b53c6c1f4587b48020; //keccak256("_CURRENT_REQUESTID");
    bytes32 constant _CURRENT_REWARD =
        0xd415862fd27fb74541e0f6f725b0c0d5b5fa1f22367d9b78ec6f61d97d05d5f8; //keccak256("_CURRENT_REWARD");
    bytes32 constant _CURRENT_TOTAL_TIPS =
        0x09659d32f99e50ac728058418d38174fe83a137c455ff1847e6fb8e15f78f77a; //keccak256("_CURRENT_TOTAL_TIPS");
    bytes32 constant _DEITY =
        0x5fc094d10c65bc33cc842217b2eccca0191ff24148319da094e540a559898961; //keccak256("_DEITY");
    bytes32 constant _DIFFICULTY =
        0xf758978fc1647996a3d9992f611883adc442931dc49488312360acc90601759b; //keccak256("_DIFFICULTY");
    bytes32 constant _DISPUTE_COUNT =
        0x310199159a20c50879ffb440b45802138b5b162ec9426720e9dd3ee8bbcdb9d7; //keccak256("_DISPUTE_COUNT");
    bytes32 constant _DISPUTE_FEE =
        0x675d2171f68d6f5545d54fb9b1fb61a0e6897e6188ca1cd664e7c9530d91ecfc; //keccak256("_DISPUTE_FEE");
    bytes32 constant _DISPUTE_ROUNDS =
        0x6ab2b18aafe78fd59c6a4092015bddd9fcacb8170f72b299074f74d76a91a923; //keccak256("_DISPUTE_ROUNDS");
    bytes32 constant _EXTENSION =
        0x2b2a1c876f73e67ebc4f1b08d10d54d62d62216382e0f4fd16c29155818207a4; //keccak256("_EXTENSION");
    bytes32 constant _FEE =
        0x1da95f11543c9b03927178e07951795dfc95c7501a9d1cf00e13414ca33bc409; //keccak256("_FEE");
    bytes32 constant _FORK_EXECUTED =
        0xda571dfc0b95cdc4a3835f5982cfdf36f73258bee7cb8eb797b4af8b17329875; //keccak256("_FORK_EXECUTED");
    bytes32 constant _LOCK =
        0xd051321aa26ce60d202f153d0c0e67687e975532ab88ce92d84f18e39895d907;
    bytes32 constant _MIGRATOR =
        0xc6b005d45c4c789dfe9e2895b51df4336782c5ff6bd59a5c5c9513955aa06307; //keccak256("_MIGRATOR");
    bytes32 constant _MIN_EXECUTION_DATE =
        0x46f7d53798d31923f6952572c6a19ad2d1a8238d26649c2f3493a6d69e425d28; //keccak256("_MIN_EXECUTION_DATE");
    bytes32 constant _MINER_SLOT =
        0x6de96ee4d33a0617f40a846309c8759048857f51b9d59a12d3c3786d4778883d; //keccak256("_MINER_SLOT");
    bytes32 constant _NUM_OF_VOTES =
        0x1da378694063870452ce03b189f48e04c1aa026348e74e6c86e10738514ad2c4; //keccak256("_NUM_OF_VOTES");
    bytes32 constant _OLD_TELLOR =
        0x56e0987db9eaec01ed9e0af003a0fd5c062371f9d23722eb4a3ebc74f16ea371; //keccak256("_OLD_TELLOR");
    bytes32 constant _ORIGINAL_ID =
        0xed92b4c1e0a9e559a31171d487ecbec963526662038ecfa3a71160bd62fb8733; //keccak256("_ORIGINAL_ID");
    bytes32 constant _OWNER =
        0x7a39905194de50bde334d18b76bbb36dddd11641d4d50b470cb837cf3bae5def; //keccak256("_OWNER");
    bytes32 constant _PAID =
        0x29169706298d2b6df50a532e958b56426de1465348b93650fca42d456eaec5fc; //keccak256("_PAID");
    bytes32 constant _PENDING_OWNER =
        0x7ec081f029b8ac7e2321f6ae8c6a6a517fda8fcbf63cabd63dfffaeaafa56cc0; //keccak256("_PENDING_OWNER");
    bytes32 constant _REQUEST_COUNT =
        0x3f8b5616fa9e7f2ce4a868fde15c58b92e77bc1acd6769bf1567629a3dc4c865; //keccak256("_REQUEST_COUNT");
    bytes32 constant _REQUEST_ID =
        0x9f47a2659c3d32b749ae717d975e7962959890862423c4318cf86e4ec220291f; //keccak256("_REQUEST_ID");
    bytes32 constant _REQUEST_Q_POSITION =
        0xf68d680ab3160f1aa5d9c3a1383c49e3e60bf3c0c031245cbb036f5ce99afaa1; //keccak256("_REQUEST_Q_POSITION");
    bytes32 constant _SLOT_PROGRESS =
        0xdfbec46864bc123768f0d134913175d9577a55bb71b9b2595fda21e21f36b082; //keccak256("_SLOT_PROGRESS");
    bytes32 constant _STAKE_AMOUNT =
        0x5d9fadfc729fd027e395e5157ef1b53ef9fa4a8f053043c5f159307543e7cc97; //keccak256("_STAKE_AMOUNT");
    bytes32 constant _STAKE_COUNT =
        0x10c168823622203e4057b65015ff4d95b4c650b308918e8c92dc32ab5a0a034b; //keccak256("_STAKE_COUNT");
    bytes32 constant _T_BLOCK =
        0xf3b93531fa65b3a18680d9ea49df06d96fbd883c4889dc7db866f8b131602dfb; //keccak256("_T_BLOCK");
    bytes32 constant _TALLY_DATE =
        0xf9e1ae10923bfc79f52e309baf8c7699edb821f91ef5b5bd07be29545917b3a6; //keccak256("_TALLY_DATE");
    bytes32 constant _TARGET_MINERS =
        0x0b8561044b4253c8df1d9ad9f9ce2e0f78e4bd42b2ed8dd2e909e85f750f3bc1; //keccak256("_TARGET_MINERS");
    bytes32 constant _TELLOR_CONTRACT =
        0x0f1293c916694ac6af4daa2f866f0448d0c2ce8847074a7896d397c961914a08; //keccak256("_TELLOR_CONTRACT");
    bytes32 constant _TELLOR_GETTERS =
        0xabd9bea65759494fe86471c8386762f989e1f2e778949e94efa4a9d1c4b3545a; //keccak256("_TELLOR_GETTERS");
    bytes32 constant _TIME_OF_LAST_NEW_VALUE =
        0x2c8b528fbaf48aaf13162a5a0519a7ad5a612da8ff8783465c17e076660a59f1; //keccak256("_TIME_OF_LAST_NEW_VALUE");
    bytes32 constant _TIME_TARGET =
        0xd4f87b8d0f3d3b7e665df74631f6100b2695daa0e30e40eeac02172e15a999e1; //keccak256("_TIME_TARGET");
    bytes32 constant _TIMESTAMP =
        0x2f9328a9c75282bec25bb04befad06926366736e0030c985108445fa728335e5; //keccak256("_TIMESTAMP");
    bytes32 constant _TOTAL_SUPPLY =
        0xe6148e7230ca038d456350e69a91b66968b222bfac9ebfbea6ff0a1fb7380160; //keccak256("_TOTAL_SUPPLY");
    bytes32 constant _TOTAL_TIP =
        0x1590276b7f31dd8e2a06f9a92867333eeb3eddbc91e73b9833e3e55d8e34f77d; //keccak256("_TOTAL_TIP");
    bytes32 constant _VALUE =
        0x9147231ab14efb72c38117f68521ddef8de64f092c18c69dbfb602ffc4de7f47; //keccak256("_VALUE");
    bytes32 constant _EIP_SLOT =
        0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IGovernance{
    enum VoteResult {FAILED,PASSED,INVALID}
    function setApprovedFunction(bytes4 _func, bool _val) external;
    function beginDispute(bytes32 _queryId,uint256 _timestamp) external;
    function delegate(address _delegate) external;
    function delegateOfAt(address _user, uint256 _blockNumber) external view returns (address);
    function executeVote(uint256 _disputeId) external;
    function proposeVote(address _contract,bytes4 _function, bytes calldata _data, uint256 _timestamp) external;
    function tallyVotes(uint256 _disputeId) external;
    function updateMinDisputeFee() external;
    function verify() external pure returns(uint);
    function vote(uint256 _disputeId, bool _supports, bool _invalidQuery) external;
    function voteFor(address[] calldata _addys,uint256 _disputeId, bool _supports, bool _invalidQuery) external;
    function getDelegateInfo(address _holder) external view returns(address,uint);
    function isApprovedGovernanceContract(address _contract) external view returns(bool);
    function isFunctionApproved(bytes4 _func) external view returns(bool);
    function getVoteCount() external view returns(uint256);
    function getVoteRounds(bytes32 _hash) external view returns(uint256[] memory);
    function getVoteInfo(uint256 _disputeId) external view returns(bytes32,uint256[8] memory,bool[2] memory,VoteResult,bytes memory,bytes4,address[2] memory);
    function getDisputeInfo(uint256 _disputeId) external view returns(uint256,uint256,bytes memory, address);
    function getOpenDisputesOnId(uint256 _queryId) external view returns(uint256);
    function didVote(uint256 _disputeId, address _voter) external view returns(bool);
    function getVoteTallyByAddress(address _voter) external view returns (uint256);
    //testing
    function testMin(uint256 a, uint256 b) external pure returns (uint256);
}