// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import './TribeAccessControl.sol';
import './interfaces/ITribe.sol';

contract Tribes is ITribe, TribeAccessControl, Pausable, ERC721Holder {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    ////////////////////////////////////////////////////////////////////////////
    // DATA
    ////////////////////////////////////////////////////////////////////////////

    enum Action {
        NONE,
        ADD_COUNCIL,
        REMOVE_COUNCIL,
        ADD_MEMBER,
        REMOVE_MEMBER
    }

    enum Vote {
        NONE,
        YES,
        NO
    }

    struct ActionInfo {
        /// @notice TribeId
        uint256 tribeId;
        /// @notice Action type
        Action action;
        /// @notice Council => YES/NO vote
        mapping(address => Vote) votes;
        /// @notice YES/NO => voter's power
        mapping(bool => uint256) powers;
    }

    struct TribeInfo {
        /// @notice BAS token's total reserve
        uint256 totalReserves;
        /// @notice Yield fee rate
        Rate yieldFeeRate;
        /// @notice Gamester tokenIds
        EnumerableSet.UintSet gamesterIds;
        /// @notice Approved councils
        EnumerableSet.AddressSet approvedCouncils;
        /// @notice Pending councils
        EnumerableSet.AddressSet pendingCouncils;
        /// @notice Approved members
        EnumerableSet.AddressSet approvedMembers;
        /// @notice Pending members
        EnumerableSet.AddressSet pendingMembers;
    }

    ////////////////////////////////////////////////////////////////////////////
    // CONSTANT
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Minimum 3 wallets in Tribe to be ACTIVE
    uint256 public constant MIN_COUNCILS = 3;
    /// @notice 10 members per council member
    uint256 public constant MEMBERS_PER_COUNCIL = 10;
    /// @notice minimum Gamester lock period
    uint256 public constant GAMESTER_LOCK_PERIOD = 1 weeks;

    ////////////////////////////////////////////////////////////////////////////
    // STATE
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Gamester NFT
    IERC721 public gamester;

    /// @notice Index => TribeInfo (Index > 0)
    mapping(uint256 => TribeInfo) private tribes;
    /// @notice Tribe indexer
    uint256 private tribeCounter;

    /// @notice Wallet => TribeId
    mapping(address => uint256) public walletTribeIds;
    /// @notice Wallet => Gamester tokenIds
    mapping(address => EnumerableSet.UintSet) private walletGamesterIds;
    /// @notice Wallet => Gamester updatedAt
    mapping(address => uint256) public walletGamesterUpdatedAt;
    /// @notice Wallet => ActionInfo
    mapping(address => ActionInfo) public walletActionInfos;

    ////////////////////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////////////////////

    event TribeCreated(
        address indexed who,
        uint256 indexed tribeId,
        Rate yieldFeeRate
    );
    event CouncilAdded(
        uint256 indexed tribeId,
        uint256 councils,
        address indexed wallet,
        uint256[] tokenIds
    );
    event CouncilRemoved(
        uint256 indexed tribeId,
        uint256 councils,
        address indexed wallet,
        uint256[] tokenIds
    );
    event MemberAdded(
        uint256 indexed tribeId,
        uint256 members,
        address indexed wallet
    );
    event MemberRemoved(
        uint256 indexed tribeId,
        uint256 members,
        address indexed wallet
    );
    event GamesterLocked(
        uint256 indexed tribeId,
        address indexed wallet,
        uint256[] tokenIds
    );
    event GamesterUnlocked(
        uint256 indexed tribeId,
        address indexed wallet,
        uint256[] tokenIds
    );
    event AddCouncilProposalCreated(
        address indexed who,
        uint256 indexed tribeId,
        address indexed wallet,
        uint256[] tokenIds
    );
    event RemoveCouncilProposalCreated(
        address indexed who,
        uint256 indexed tribeId,
        address indexed wallet
    );
    event AddMemberProposalCreated(
        address indexed who,
        uint256 indexed tribeId,
        address indexed wallet
    );
    event RemoveMemberProposalCreated(
        address indexed who,
        uint256 indexed tribeId,
        address indexed wallet
    );
    event Voted(
        address indexed who,
        uint256 indexed tribeId,
        address indexed wallet,
        Action action,
        bool vote,
        uint256 yesPower,
        uint256 noPower
    );
    event Operated(
        address indexed who,
        uint256 indexed tribeId,
        address indexed wallet,
        Action action
    );
    event Cancelled(
        address indexed who,
        uint256 indexed tribeId,
        address indexed wallet,
        Action action
    );
    event BASAdded(
        address indexed who,
        uint256 indexed tribeId,
        uint256 amount
    );
    event BASRemoved(
        address indexed who,
        uint256 indexed tribeId,
        uint256 amount
    );

    ////////////////////////////////////////////////////////////////////////////
    // CONSTRUCTOR
    ////////////////////////////////////////////////////////////////////////////

    constructor(address _provider, address _gamester)
        TribeAccessControl(_provider)
    {
        require(_gamester != address(0), 'invalid gamester');

        gamester = IERC721(_gamester);
    }

    ////////////////////////////////////////////////////////////////////////////
    // Modifier
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev if Tribe is active
     * @param _tribeId Tribe id
     */
    modifier onlyActiveTribe(uint256 _tribeId) {
        TribeInfo storage tribeInfo = tribes[_tribeId];

        // if active tribe
        require(
            tribeInfo.approvedCouncils.length() >= MIN_COUNCILS,
            'pending tribe'
        );

        _;
    }

    /**
     * @dev if sender is approved member or council
     * @param _tribeId Tribe Id
     */
    modifier onlyApprovedMember(uint256 _tribeId) {
        TribeInfo storage tribeInfo = tribes[_tribeId];

        // if approved member or council
        require(
            tribeInfo.approvedCouncils.contains(msg.sender) ||
                tribeInfo.approvedMembers.contains(msg.sender),
            'not approved member'
        );

        _;
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @notice create a new Tribe
     * @dev wallet not in Tribe already and needs to lock at least 1 Gamester
     * @param _tokenIds Gamester tokenIds to lock
     * @param _yieldFeeRate Yield fee rate
     */
    function createTribe(
        uint256[] memory _tokenIds,
        Rate calldata _yieldFeeRate
    ) external whenNotPaused {
        // if wallet not in Tribe already
        require(walletTribeIds[msg.sender] == 0, 'already in Tribe');

        // needs to lock at least 1 Gamester
        uint256 length = _tokenIds.length;
        require(length > 0, 'zero gamester');

        // validate rate
        _validateRate(_yieldFeeRate);

        // create a new Tribe
        tribeCounter += 1;
        TribeInfo storage tribeInfo = tribes[tribeCounter];
        tribeInfo.yieldFeeRate = _yieldFeeRate;

        // add an approved council
        tribeInfo.approvedCouncils.add(msg.sender);
        walletTribeIds[msg.sender] = tribeCounter;
        walletGamesterUpdatedAt[msg.sender] = block.timestamp;

        // lock Gamesters
        EnumerableSet.UintSet storage _walletGamesterIds = walletGamesterIds[
            msg.sender
        ];
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = _tokenIds[i];

            tribeInfo.gamesterIds.add(tokenId);
            _walletGamesterIds.add(tokenId);

            gamester.safeTransferFrom(msg.sender, address(this), tokenId);
        }

        // event
        emit TribeCreated(msg.sender, tribeCounter, _yieldFeeRate);
        emit CouncilAdded(tribeCounter, 1, msg.sender, _tokenIds);
    }

    /**
     * @notice approved council can add a new one directly
     * @param _tribeId Tribe Id
     * @param _wallet new council address
     * @param _tokenIds Gamester tokenIds to lock
     */
    function addCouncilByApprovedCouncil(
        uint256 _tribeId,
        address _wallet,
        uint256[] memory _tokenIds
    ) external whenNotPaused {
        // if valid Tribe
        require(_tribeId > 0, 'invalid tribeId');

        // if caller is approved council
        TribeInfo storage tribeInfo = tribes[_tribeId];
        require(
            tribeInfo.approvedCouncils.contains(msg.sender),
            'not approved council'
        );

        // if wallet not in Tribe already
        require(walletTribeIds[_wallet] == 0, 'already in Tribe');

        // needs to lock at least 1 Gamester
        uint256 length = _tokenIds.length;
        require(length > 0, 'zero gamester');

        // add an approved council
        tribeInfo.approvedCouncils.add(_wallet);
        walletTribeIds[_wallet] = _tribeId;
        walletGamesterUpdatedAt[_wallet] = block.timestamp;

        // lock Gamesters
        EnumerableSet.UintSet storage _walletGamesterIds = walletGamesterIds[
            _wallet
        ];
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = _tokenIds[i];

            tribeInfo.gamesterIds.add(tokenId);
            _walletGamesterIds.add(tokenId);

            gamester.safeTransferFrom(_wallet, address(this), tokenId);
        }

        // event
        emit CouncilAdded(
            _tribeId,
            tribeInfo.approvedCouncils.length(),
            _wallet,
            _tokenIds
        );
    }

    /**
     * @notice make a proposal to add a new council
     * @param _tribeId Tribe Id
     * @param _wallet new council address
     * @param _tokenIds Gamester tokenIds to lock
     */
    function proposeToAddCouncil(
        uint256 _tribeId,
        address _wallet,
        uint256[] memory _tokenIds
    ) external whenNotPaused {
        // if wallet not in Tribe already
        require(walletTribeIds[_wallet] == 0, 'already in Tribe');

        // needs to lock at least 1 Gamester
        uint256 length = _tokenIds.length;
        require(length > 0, 'zero gamester');

        // if valid Tribe
        require(_tribeId > 0, 'invalid tribeId');
        TribeInfo storage tribeInfo = tribes[_tribeId];
        require(tribeInfo.approvedCouncils.length() > 0, 'invalid Tribe');

        // add a new pending council
        tribeInfo.pendingCouncils.add(_wallet);
        walletTribeIds[_wallet] = _tribeId;

        // create a new Action
        ActionInfo storage actionInfo = walletActionInfos[_wallet];
        actionInfo.tribeId = _tribeId;
        actionInfo.action = Action.ADD_COUNCIL;

        // lock Gamesters
        EnumerableSet.UintSet storage _walletGamesterIds = walletGamesterIds[
            _wallet
        ];
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = _tokenIds[i];

            _walletGamesterIds.add(tokenId);

            gamester.safeTransferFrom(_wallet, address(this), tokenId);
        }

        // event
        emit AddCouncilProposalCreated(
            msg.sender,
            _tribeId,
            _wallet,
            _tokenIds
        );
    }

    /**
     * @notice make a proposal to remove an old council
     * @param _wallet old council address
     */
    function proposeToRemoveCouncil(address _wallet) external whenNotPaused {
        // if wallet in Tribe already
        uint256 tribeId = walletTribeIds[_wallet];
        require(tribeId > 0, 'not in Tribe');

        // if wallet is an approved council
        TribeInfo storage tribeInfo = tribes[tribeId];
        require(
            tribeInfo.approvedCouncils.contains(_wallet),
            'not approved council'
        );

        // if empty action
        ActionInfo storage actionInfo = walletActionInfos[_wallet];
        require(actionInfo.tribeId == 0, 'existing proposal');

        // create a new Action
        actionInfo.tribeId = tribeId;
        actionInfo.action = Action.REMOVE_COUNCIL;

        // event
        emit RemoveCouncilProposalCreated(msg.sender, tribeId, _wallet);
    }

    /**
     * @notice make a proposal to add a new member
     * @param _tribeId Tribe Id
     * @param _wallet new member address
     */
    function proposeToAddMember(uint256 _tribeId, address _wallet)
        external
        whenNotPaused
    {
        // if wallet not in Tribe already
        require(walletTribeIds[_wallet] == 0, 'already in Tribe');

        // if valid Tribe
        require(_tribeId > 0, 'invalid tribeId');

        // if no limit for adding new member
        TribeInfo storage tribeInfo = tribes[_tribeId];
        require(
            tribeInfo.approvedMembers.length() <
                tribeInfo.approvedCouncils.length() * MEMBERS_PER_COUNCIL,
            'limited members'
        );

        // add a new pending member
        tribeInfo.pendingMembers.add(_wallet);
        walletTribeIds[_wallet] = _tribeId;

        // create a new Action
        ActionInfo storage actionInfo = walletActionInfos[_wallet];
        actionInfo.tribeId = _tribeId;
        actionInfo.action = Action.ADD_MEMBER;

        // event
        emit AddMemberProposalCreated(msg.sender, _tribeId, _wallet);
    }

    /**
     * @notice make a proposal to remove an old member
     * @param _wallet old member address
     */
    function proposeToRemoveMember(address _wallet) external whenNotPaused {
        // if wallet in Tribe already
        uint256 tribeId = walletTribeIds[_wallet];
        require(tribeId > 0, 'not in Tribe');

        // if wallet is an approved member
        TribeInfo storage tribeInfo = tribes[tribeId];
        require(
            tribeInfo.approvedMembers.contains(_wallet),
            'not approved member'
        );

        // if empty action
        ActionInfo storage actionInfo = walletActionInfos[_wallet];
        require(actionInfo.tribeId == 0, 'existing proposal');

        // create a new Action
        actionInfo.tribeId = tribeId;
        actionInfo.action = Action.REMOVE_MEMBER;

        // event
        emit RemoveMemberProposalCreated(msg.sender, tribeId, _wallet);
    }

    /**
     * @notice vote to the proposal
     * @dev only approved councils can vote
     * @param _wallet proposal for whom
     * @param _vote YES/NO
     */
    function vote(address _wallet, bool _vote) external whenNotPaused {
        // if valid action
        ActionInfo storage actionInfo = walletActionInfos[_wallet];
        require(
            actionInfo.tribeId > 0 && actionInfo.action != Action.NONE,
            'invalid action'
        );

        // if vote by approved council
        TribeInfo storage tribeInfo = tribes[actionInfo.tribeId];
        require(
            tribeInfo.approvedCouncils.contains(msg.sender),
            'not approved council'
        );

        // if vote already
        require(actionInfo.votes[msg.sender] == Vote.NONE, 'vote already');

        // set vote
        actionInfo.votes[msg.sender] = _vote ? Vote.YES : Vote.NO;

        // update power
        actionInfo.powers[_vote] += walletGamesterIds[msg.sender].length();

        // event
        emit Voted(
            msg.sender,
            actionInfo.tribeId,
            _wallet,
            actionInfo.action,
            _vote,
            actionInfo.powers[true],
            actionInfo.powers[false]
        );
    }

    /**
     * @notice operate the proposal
     * @dev power should be mucher than half of locked gamesters
     * @param _wallet proposal for whom
     */
    function operate(address _wallet) external whenNotPaused {
        // if valid action
        ActionInfo storage actionInfo = walletActionInfos[_wallet];
        require(
            actionInfo.tribeId > 0 && actionInfo.action != Action.NONE,
            'invalid action'
        );

        TribeInfo storage tribeInfo = tribes[actionInfo.tribeId];
        uint256 totalTribeGamesters = tribeInfo.gamesterIds.length();

        // if enough YES vote
        if (actionInfo.powers[true] > (totalTribeGamesters / 2)) {
            // add council
            if (actionInfo.action == Action.ADD_COUNCIL) {
                _addCouncil(actionInfo.tribeId, _wallet);
            }
            // remove council
            else if (actionInfo.action == Action.REMOVE_COUNCIL) {
                _removeCouncil(actionInfo.tribeId, _wallet);
            }
            // add member
            else if (actionInfo.action == Action.ADD_MEMBER) {
                _addMember(actionInfo.tribeId, _wallet);
            }
            // remove member
            else if (actionInfo.action == Action.REMOVE_MEMBER) {
                _removeMember(actionInfo.tribeId, _wallet);
            }

            // event
            emit Operated(
                msg.sender,
                actionInfo.tribeId,
                _wallet,
                actionInfo.action
            );
        }
        // if enough NO vote
        else if (
            actionInfo.powers[false] >=
            (totalTribeGamesters - totalTribeGamesters / 2)
        ) {
            // cancel add council
            if (actionInfo.action == Action.ADD_COUNCIL) {
                // remove pending council
                tribeInfo.pendingCouncils.remove(_wallet);

                // return locked Gamesters
                EnumerableSet.UintSet
                    storage _walletGamesterIds = walletGamesterIds[_wallet];
                uint256 length = _walletGamesterIds.length();

                for (uint256 i = 0; i < length; i++) {
                    gamester.safeTransferFrom(
                        address(this),
                        _wallet,
                        _walletGamesterIds.at(i)
                    );
                }

                // clear gamester Ids
                delete walletGamesterIds[_wallet];
            }
            // cancel add member
            else if (actionInfo.action == Action.ADD_MEMBER) {
                // remove pending member
                tribeInfo.pendingMembers.remove(_wallet);
            }

            // clear wallet TribeId
            delete walletTribeIds[_wallet];

            // event
            emit Cancelled(
                msg.sender,
                actionInfo.tribeId,
                _wallet,
                actionInfo.action
            );
        }
        // if no enough YES or NO vote
        else {
            revert('no enough vote');
        }

        // clear action info
        delete walletActionInfos[_wallet];
    }

    /**
     * @notice cancel ADD_COUNCIL or ADD_MEMBER action
     * @dev only owner can call it
     */
    function cancel() external whenNotPaused {
        // if valid action
        ActionInfo storage actionInfo = walletActionInfos[msg.sender];
        require(actionInfo.tribeId > 0, 'invalid action');

        TribeInfo storage tribeInfo = tribes[actionInfo.tribeId];

        // cancel add council
        if (actionInfo.action == Action.ADD_COUNCIL) {
            // remove pending council
            tribeInfo.pendingCouncils.remove(msg.sender);

            // return locked Gamesters
            EnumerableSet.UintSet
                storage _walletGamesterIds = walletGamesterIds[msg.sender];
            uint256 length = _walletGamesterIds.length();

            for (uint256 i = 0; i < length; i++) {
                gamester.safeTransferFrom(
                    address(this),
                    msg.sender,
                    _walletGamesterIds.at(i)
                );
            }

            // clear gamester Ids
            delete walletGamesterIds[msg.sender];
        }
        // cancel add member
        else if (actionInfo.action == Action.ADD_MEMBER) {
            // remove pending member
            tribeInfo.pendingMembers.remove(msg.sender);
        }
        // revert if other actions
        else {
            revert('cannot cancel');
        }

        // event
        emit Cancelled(
            msg.sender,
            actionInfo.tribeId,
            msg.sender,
            actionInfo.action
        );

        // clear action info
        delete walletActionInfos[msg.sender];
    }

    /**
     * @notice lock more Gamesters
     * @param _tokenIds Gamester tokenIds to lock
     */
    function lockGamesters(uint256[] memory _tokenIds) external whenNotPaused {
        // needs to lock at least 1 Gamester
        uint256 length = _tokenIds.length;
        require(length > 0, 'zero gamester');

        // if wallet in Tribe already
        uint256 tribeId = walletTribeIds[msg.sender];
        require(tribeId > 0, 'not in Tribe');

        // if wallet is an approved council
        TribeInfo storage tribeInfo = tribes[tribeId];
        require(
            tribeInfo.approvedCouncils.contains(msg.sender),
            'not approved council'
        );

        // wallet Gamester updatedAt
        walletGamesterUpdatedAt[msg.sender] = block.timestamp;

        // lock Gamesters
        EnumerableSet.UintSet storage _walletGamesterIds = walletGamesterIds[
            msg.sender
        ];
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = _tokenIds[i];

            tribeInfo.gamesterIds.add(tokenId);
            _walletGamesterIds.add(tokenId);

            gamester.safeTransferFrom(msg.sender, address(this), tokenId);
        }

        // increase vote power for pending councils
        for (uint256 i = 0; i < tribeInfo.pendingCouncils.length(); i++) {
            address pending = tribeInfo.pendingCouncils.at(i);
            ActionInfo storage actionInfo = walletActionInfos[pending];

            // YES vote
            if (actionInfo.votes[msg.sender] == Vote.YES) {
                actionInfo.powers[true] += length;
            }
            // NO vote
            else if (actionInfo.votes[msg.sender] == Vote.NO) {
                actionInfo.powers[false] += length;
            }
        }

        // increase vote power for pending members
        for (uint256 i = 0; i < tribeInfo.pendingMembers.length(); i++) {
            address pending = tribeInfo.pendingMembers.at(i);
            ActionInfo storage actionInfo = walletActionInfos[pending];

            // YES vote
            if (actionInfo.votes[msg.sender] == Vote.YES) {
                actionInfo.powers[true] += length;
            }
            // NO vote
            else if (actionInfo.votes[msg.sender] == Vote.NO) {
                actionInfo.powers[false] += length;
            }
        }

        // event
        emit GamesterLocked(tribeId, msg.sender, _tokenIds);
    }

    /**
     * @notice unlock Gamesters
     * @dev locked at least GAMESTER_LOCK_PERIOD
     * @param _tokenIds Gamester tokenIds to unlock
     */
    function unlockGamesters(uint256[] memory _tokenIds)
        external
        whenNotPaused
    {
        // needs to lock at least 1 Gamester
        uint256 length = _tokenIds.length;
        require(length > 0, 'zero gamester');

        // if wallet in Tribe already
        uint256 tribeId = walletTribeIds[msg.sender];
        require(tribeId > 0, 'not in Tribe');

        // if wallet is an approved council
        TribeInfo storage tribeInfo = tribes[tribeId];
        require(
            tribeInfo.approvedCouncils.contains(msg.sender),
            'not approved council'
        );

        // locked at least GAMESTER_LOCK_PERIOD
        require(
            block.timestamp >=
                walletGamesterUpdatedAt[msg.sender] + GAMESTER_LOCK_PERIOD,
            'locked'
        );

        // wallet Gamester updatedAt
        walletGamesterUpdatedAt[msg.sender] = block.timestamp;

        // unlock Gamesters
        EnumerableSet.UintSet storage _walletGamesterIds = walletGamesterIds[
            msg.sender
        ];
        require(_walletGamesterIds.length() > length, 'cannot unlock all');

        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = _tokenIds[i];

            require(_walletGamesterIds.remove(tokenId), 'not owned tokenId');
            tribeInfo.gamesterIds.remove(tokenId);

            gamester.safeTransferFrom(address(this), msg.sender, tokenId);
        }

        // decrease vote power for pending councils
        for (uint256 i = 0; i < tribeInfo.pendingCouncils.length(); i++) {
            address pending = tribeInfo.pendingCouncils.at(i);
            ActionInfo storage actionInfo = walletActionInfos[pending];

            // YES vote
            if (actionInfo.votes[msg.sender] == Vote.YES) {
                actionInfo.powers[true] -= length;
            }
            // NO vote
            else if (actionInfo.votes[msg.sender] == Vote.NO) {
                actionInfo.powers[false] -= length;
            }
        }

        // decrease vote power for pending members
        for (uint256 i = 0; i < tribeInfo.pendingMembers.length(); i++) {
            address pending = tribeInfo.pendingMembers.at(i);
            ActionInfo storage actionInfo = walletActionInfos[pending];

            // YES vote
            if (actionInfo.votes[msg.sender] == Vote.YES) {
                actionInfo.powers[true] -= length;
            }
            // NO vote
            else if (actionInfo.votes[msg.sender] == Vote.NO) {
                actionInfo.powers[false] -= length;
            }
        }

        // event
        emit GamesterUnlocked(tribeId, msg.sender, _tokenIds);
    }

    /**
     * @notice stake BAS token
     * @param _tribeId Tribe Id
     * @param _amount BAS token amount
     */
    function addBASToTribe(uint256 _tribeId, uint256 _amount)
        external
        whenNotPaused
        onlyActiveTribe(_tribeId)
        onlyApprovedMember(_tribeId)
    {
        require(_amount > 0, 'invalid amount');

        // update totalReserves in Tribe
        TribeInfo storage tribeInfo = tribes[_tribeId];
        tribeInfo.totalReserves += _amount;

        // deposit into BAS vault
        getVault().depositFrom(msg.sender, _amount);

        // event
        emit BASAdded(msg.sender, _tribeId, _amount);
    }

    /**
     * @notice withdraw BAS token
     * @param _tribeId Tribe Id
     * @param _amount BAS token amount
     */
    function removeBASFromTribe(uint256 _tribeId, uint256 _amount)
        external
        whenNotPaused
    {
        require(_amount > 0, 'invalid amount');

        // update totalReserves in Tribe
        TribeInfo storage tribeInfo = tribes[_tribeId];
        tribeInfo.totalReserves -= _amount;

        // withdraw from BAS vault
        getVault().withdrawTo(msg.sender, _amount);

        // event
        emit BASRemoved(msg.sender, _tribeId, _amount);
    }

    ////////////////////////////////////////////////////////////////////////////
    /// ADMIN
    ////////////////////////////////////////////////////////////////////////////

    function pause() external onlyOwner whenNotPaused {
        return _pause();
    }

    function unpause() external onlyOwner whenPaused {
        return _unpause();
    }

    ////////////////////////////////////////////////////////////////////////////
    /// INTERNAL
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @notice add a new council to Tribe
     * @param _tribeId Tribe Id
     * @param _wallet new council address
     */
    function _addCouncil(uint256 _tribeId, address _wallet) internal {
        // if valid Tribe
        require(_tribeId > 0, 'invalid tribeId');

        // if wallet is pending council
        TribeInfo storage tribeInfo = tribes[_tribeId];
        require(
            tribeInfo.pendingCouncils.contains(_wallet),
            'not pending council'
        );

        // locked at least 1 Gamester
        EnumerableSet.UintSet storage _walletGamesterIds = walletGamesterIds[
            _wallet
        ];
        uint256 length = _walletGamesterIds.length();
        require(length > 0, 'zero gamester');

        // add an approved council
        tribeInfo.approvedCouncils.add(_wallet);
        tribeInfo.pendingCouncils.remove(_wallet);
        walletGamesterUpdatedAt[_wallet] = block.timestamp;

        for (uint256 i = 0; i < length; i++) {
            tribeInfo.gamesterIds.add(_walletGamesterIds.at(i));
        }

        // event
        emit CouncilAdded(
            _tribeId,
            tribeInfo.approvedCouncils.length(),
            _wallet,
            _setToUintArray(_walletGamesterIds)
        );
    }

    /**
     * @notice remove old council from Tribe
     * @param _tribeId Tribe Id
     * @param _wallet old council address
     */
    function _removeCouncil(uint256 _tribeId, address _wallet) internal {
        // if valid Tribe
        require(_tribeId > 0, 'invalid tribeId');

        // if wallet is approved council
        TribeInfo storage tribeInfo = tribes[_tribeId];
        require(
            tribeInfo.approvedCouncils.contains(_wallet),
            'not approved council'
        );

        // remove an approved council
        tribeInfo.approvedCouncils.remove(_wallet);
        walletTribeIds[_wallet] = 0;

        // remove council's BAS
        tribeInfo.totalReserves -= getVault().balanceOf(_wallet);

        // return locked Gamesters
        EnumerableSet.UintSet storage _walletGamesterIds = walletGamesterIds[
            _wallet
        ];
        uint256 length = _walletGamesterIds.length();

        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = _walletGamesterIds.at(i);

            tribeInfo.gamesterIds.remove(tokenId);
            gamester.safeTransferFrom(address(this), _wallet, tokenId);
        }

        // remove last members
        uint256 councils = tribeInfo.approvedCouncils.length();
        for (
            uint256 i = councils * MEMBERS_PER_COUNCIL;
            i < tribeInfo.approvedMembers.length();
            i++
        ) {
            _removeMember(_tribeId, tribeInfo.approvedMembers.at(i));
        }

        // event
        emit CouncilRemoved(
            _tribeId,
            councils,
            _wallet,
            _setToUintArray(_walletGamesterIds)
        );

        // clear gamester Ids
        delete walletGamesterIds[_wallet];
    }

    /**
     * @notice add a new member to Tribe
     * @param _tribeId Tribe Id
     * @param _wallet new member address
     */
    function _addMember(uint256 _tribeId, address _wallet) internal {
        // if valid Tribe
        require(_tribeId > 0, 'invalid tribeId');

        // if wallet is pending member
        TribeInfo storage tribeInfo = tribes[_tribeId];
        require(
            tribeInfo.pendingMembers.contains(_wallet),
            'not pending member'
        );

        // if no limit for adding new member
        require(
            tribeInfo.approvedMembers.length() <
                tribeInfo.approvedCouncils.length() * MEMBERS_PER_COUNCIL,
            'limited members'
        );

        // add an approved member
        tribeInfo.approvedMembers.add(_wallet);
        tribeInfo.pendingMembers.remove(_wallet);

        // event
        emit MemberAdded(_tribeId, tribeInfo.approvedMembers.length(), _wallet);
    }

    /**
     * @notice remove old member from Tribe
     * @param _tribeId Tribe Id
     * @param _wallet old member address
     */
    function _removeMember(uint256 _tribeId, address _wallet) internal {
        // if valid Tribe
        require(_tribeId > 0, 'invalid tribeId');

        // if wallet is approved member
        TribeInfo storage tribeInfo = tribes[_tribeId];
        require(
            tribeInfo.approvedMembers.contains(_wallet),
            'not approved member'
        );

        // remove an approved member
        tribeInfo.approvedMembers.remove(_wallet);
        walletTribeIds[_wallet] = 0;

        // remove member's BAS
        tribeInfo.totalReserves -= getVault().balanceOf(_wallet);

        // event
        emit MemberRemoved(
            _tribeId,
            tribeInfo.approvedMembers.length(),
            _wallet
        );
    }

    /**
     * @notice EnumerableSet.UintSet to uint array
     * @param _set EnumerableSet.UintSet
     */
    function _setToUintArray(EnumerableSet.UintSet storage _set)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 length = _set.length();
        uint256[] memory array = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            array[i] = _set.at(i);
        }

        return array;
    }

    /**
     * @notice EnumerableSet.AddressSet to address array
     * @param _set EnumerableSet.AddressSet
     */
    function _setToAddressArray(EnumerableSet.AddressSet storage _set)
        internal
        view
        returns (address[] memory)
    {
        uint256 length = _set.length();
        address[] memory array = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            array[i] = _set.at(i);
        }

        return array;
    }

    /**
     * @notice Validate rate denominator and numerator
     * @param _rate in numerator/denominator
     */
    function _validateRate(Rate memory _rate) internal pure {
        require(
            _rate.denominator > 0 && _rate.denominator >= _rate.numerator,
            'invalid rate'
        );
    }

    ////////////////////////////////////////////////////////////////////////////
    // VIEW
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Tribe status - true: ACTIVE, false: PENDING
     * @param _tribeId Tribe Id
     */
    function tribeStatus(uint256 _tribeId) public view returns (bool) {
        TribeInfo storage tribeInfo = tribes[_tribeId];
        return tribeInfo.approvedCouncils.length() >= MIN_COUNCILS;
    }

    /**
     * @notice if wallet is approved council or member
     * @param _wallet address
     */
    function isApproved(address _wallet) external view returns (bool) {
        // if wallet in Tribe already
        uint256 tribeId = walletTribeIds[_wallet];
        if (tribeId == 0) {
            return false;
        }

        TribeInfo storage tribeInfo = tribes[tribeId];

        // if wallet is approved council
        if (tribeInfo.approvedCouncils.contains(_wallet)) {
            return true;
        }
        // if wallet is approved member
        if (tribeInfo.approvedMembers.contains(_wallet)) {
            return true;
        }

        return false;
    }

    /**
     * @notice returns tribeId and average BAS staked in Tribe
     * @param _wallet council/member address
     */
    function viewTribeByWallet(address _wallet)
        external
        view
        returns (
            uint256 tribeId,
            uint256 totalReserves,
            uint256 approvedWallets,
            uint256 averageBAS,
            uint256 balance,
            uint256[] memory gamesterIds
        )
    {
        // if wallet in Tribe already
        tribeId = walletTribeIds[_wallet];
        require(tribeId > 0, 'not in Tribe');

        // calculate approvedWallets = approvedCouncils + approvedMembers
        // calculate averageBAS = totalReserves / approvedWallets
        TribeInfo storage tribeInfo = tribes[tribeId];
        totalReserves = tribeInfo.totalReserves;
        approvedWallets =
            tribeInfo.approvedCouncils.length() +
            tribeInfo.approvedMembers.length();
        averageBAS = tribeInfo.totalReserves / approvedWallets;

        // calculate wallet's balance in BAS vault
        balance = getVault().balanceOf(_wallet);

        // wallet's locked gamesterIds
        gamesterIds = _setToUintArray(walletGamesterIds[_wallet]);
    }

    /**
     * @notice returns Tribe's totalReserves, yieldFeeRate, gamesterIds, approvedCouncils, approvedCouncilsBalances, approvedMembers, approvedMembersBalances
     * @param _tribeId Tribe Id
     */
    function viewTribeInfo(uint256 _tribeId)
        external
        view
        returns (
            uint256 totalReserves,
            Rate memory yieldFeeRate,
            uint256[] memory gamesterIds,
            address[] memory approvedCouncils,
            uint256[] memory approvedCouncilsBalances,
            address[] memory approvedMembers,
            uint256[] memory approvedMembersBalances
        )
    {
        TribeInfo storage tribeInfo = tribes[_tribeId];

        totalReserves = tribeInfo.totalReserves;
        yieldFeeRate = tribeInfo.yieldFeeRate;
        gamesterIds = _setToUintArray(tribeInfo.gamesterIds);
        approvedCouncils = _setToAddressArray(tribeInfo.approvedCouncils);
        approvedMembers = _setToAddressArray(tribeInfo.approvedMembers);

        IBASVault vault = getVault();

        uint256 councils = approvedCouncils.length;
        approvedCouncilsBalances = new uint256[](councils);
        for (uint256 i = 0; i < councils; i++) {
            approvedCouncilsBalances[i] = vault.balanceOf(approvedCouncils[i]);
        }

        uint256 members = approvedCouncils.length;
        approvedMembersBalances = new uint256[](members);
        for (uint256 i = 0; i < members; i++) {
            approvedMembersBalances[i] = vault.balanceOf(approvedMembers[i]);
        }
    }

    /**
     * @notice returns Tribe's pendingCouncils, pendingMembers
     * @param _tribeId Tribe Id
     */
    function viewTribePendingInfo(uint256 _tribeId)
        external
        view
        returns (
            address[] memory pendingCouncils,
            address[] memory pendingMembers
        )
    {
        TribeInfo storage tribeInfo = tribes[_tribeId];

        pendingCouncils = _setToAddressArray(tribeInfo.pendingCouncils);
        pendingMembers = _setToAddressArray(tribeInfo.pendingMembers);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

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
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
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
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/access/Ownable.sol';

import './interfaces/ITribeAddressRegistry.sol';
import './interfaces/IBASVault.sol';
import './interfaces/ITribe.sol';

contract TribeAccessControl is Ownable {
    ITribeAddressRegistry internal addressProvider;

    constructor(address _provider) {
        addressProvider = ITribeAddressRegistry(_provider);
    }

    modifier onlyTribe() {
        require(
            _msgSender() == addressProvider.getTribe(),
            'AccessControl: Invalid tribe'
        );
        _;
    }

    function setAddressProvider(address _provider) external onlyOwner {
        addressProvider = ITribeAddressRegistry(_provider);
    }

    function getVault() internal view returns (IBASVault) {
        return IBASVault(addressProvider.getVault());
    }

    function getTribe() internal view returns (ITribe) {
        return ITribe(addressProvider.getTribe());
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface ITribe {
    struct Rate {
        uint128 numerator;
        uint128 denominator;
    }

    function isApproved(address _wallet) external view returns (bool);

    function viewTribeByWallet(address _wallet)
        external
        view
        returns (
            uint256 tribeId,
            uint256 totalReserves,
            uint256 approvedWallets,
            uint256 averageBAS,
            uint256 balance,
            uint256[] memory gamesterIds
        );

    function viewTribeInfo(uint256 _tribeId)
        external
        view
        returns (
            uint256 totalReserves,
            Rate memory yieldFeeRate,
            uint256[] memory gamesterIds,
            address[] memory approvedCouncils,
            uint256[] memory approvedCouncilsBalances,
            address[] memory approvedMembers,
            uint256[] memory approvedMembersBalances
        );

    function viewTribePendingInfo(uint256 _tribeId)
        external
        view
        returns (
            address[] memory pendingCouncils,
            address[] memory pendingMembers
        );
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface ITribeAddressRegistry {
    function initialize(address _vault, address _tribe) external;

    function getVault() external view returns (address);

    function setVault(address _vault) external;

    function getTribe() external view returns (address);

    function setTribe(address _tribe) external;

    function getAddress(bytes32 id) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface IBASVault {
    function balanceOf(address _wallet) external view returns (uint256);

    function deposit(uint256 _amount) external;

    function depositFrom(address _from, uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function withdrawTo(address _to, uint256 _amount) external;
}