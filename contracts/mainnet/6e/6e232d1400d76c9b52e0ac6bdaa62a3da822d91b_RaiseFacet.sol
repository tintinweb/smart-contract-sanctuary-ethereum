// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

// OpenZeppelin imports
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Local imports
import { AccessTypes } from "../structs/AccessTypes.sol";
import { BaseTypes } from "../structs/BaseTypes.sol";
import { RequestTypes } from "../structs/RequestTypes.sol";
import { LibAccessControl } from "../libraries/LibAccessControl.sol";
import { LibMilestone } from "../libraries/LibMilestone.sol";
import { LibNonce } from "../libraries/LibNonce.sol";
import { LibRaise } from "../libraries/LibRaise.sol";
import { LibSignature } from "../../libraries/LibSignature.sol";
import { IRaiseFacet } from "../interfaces/IRaiseFacet.sol";

/**************************************

    Raise facet

**************************************/

contract RaiseFacet is IRaiseFacet {
    using SafeERC20 for IERC20;

    // versioning: "release:major:minor"
    bytes32 constant EIP712_NAME = keccak256(bytes("Fundraising:Raise"));
    bytes32 constant EIP712_VERSION = keccak256(bytes("1:0:0"));

    // typehashes
    bytes32 constant STARTUP_CREATE_RAISE_TYPEHASH = keccak256("CreateRaiseRequest(bytes raise,bytes vested,bytes milestones,bytes base)");
    bytes32 constant INVESTOR_INVEST_TYPEHASH = keccak256("InvestRequest(string raiseId,uint256 investment,uint256 maxTicketSize,bytes base)");

    // constants
    uint256 constant USDT_DECIMALS = 10**6;

    /**************************************

        Create new raise

     **************************************/

    function createRaise(
        RequestTypes.CreateRaiseRequest calldata _request,
        bytes32 _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {

        // tx.members
        address sender_ = msg.sender;
        address self_ = address(this);

        // request.members
        BaseTypes.Raise memory raise_ = _request.raise;
        string memory raiseId_ = raise_.raiseId;

        // validate request
        _validateCreateRaiseRequest(_request);

        // verify if raise does not exist
        LibRaise.verifyRaise(raiseId_);

        // eip712 encoding
        bytes memory encodedMsg_ = _encodeCreateRaise(_request);

        // verify message
        LibSignature.verifyMessage(
            EIP712_NAME,
            EIP712_VERSION,
            keccak256(encodedMsg_),
            _message
        );

        // verify signer of signature
        _verifySignature(
            _message,
            _v,
            _r,
            _s
        );

        // erc20
        IERC20 erc20_ = IERC20(_request.vested.erc20);

        // allowance check
        uint256 allowance_ = erc20_.allowance(
            sender_,
            self_
        );
        if (allowance_ < _request.vested.amount) {
            revert NotEnoughAllowance(sender_, self_, allowance_);
        }

        // vest erc20
        erc20_.safeTransferFrom(
            sender_,
            self_,
            _request.vested.amount
        );

        // save storage
        LibNonce.setNonce(sender_, _request.base.nonce);
        LibRaise.saveRaise(
            raiseId_,
            raise_,
            _request.vested
        );
        LibMilestone.saveMilestones(
            raiseId_,
            _request.milestones
        );

        // emit event
        emit NewRaise(sender_, raise_, _request.milestones, _message);

    }

    function _validateCreateRaiseRequest(
        RequestTypes.CreateRaiseRequest memory _request
    ) internal view {

        // tx.members
        address sender_ = msg.sender;
        uint256 now_ = block.timestamp;

        // check replay attack
        uint256 nonce_ = _request.base.nonce;
        if (nonce_ <= LibNonce.getLastNonce(sender_)) {
            revert NonceExpired(sender_, nonce_);
        }

        // check request expiration
        if (now_ > _request.base.expiry) {
            revert RequestExpired(sender_, abi.encode(_request));
        }

        // check request sender
        if (sender_ != _request.base.sender) {
            revert IncorrectSender(sender_);
        }

        // check raise id
        if (bytes(_request.raise.raiseId).length == 0) {
            revert InvalidRaiseId(_request.raise.raiseId);
        }

        // check milestone count
        if (_request.milestones.length == 0) {
            revert InvalidMilestoneCount(_request.milestones);
        }

        // check start and end date
        if (_request.raise.start >= _request.raise.end) {
            revert InvalidMilestoneStartEnd(_request.raise.start, _request.raise.end);
        }

    }

    function _encodeCreateRaise(
        RequestTypes.CreateRaiseRequest memory _request
    ) internal pure
    returns (bytes memory) {

        // raise
        bytes memory encodedRaise_ = abi.encode(_request.raise);

        // vested
        bytes memory encodedVested_ = abi.encode(_request.vested);

        // milestones
        bytes memory encodedMilestones_ = abi.encode(_request.milestones);

        // base
        bytes memory encodedBase_ = abi.encode(_request.base);

        // msg
        bytes memory encodedMsg_ = abi.encode(
            STARTUP_CREATE_RAISE_TYPEHASH,
            keccak256(encodedRaise_),
            keccak256(encodedVested_),
            keccak256(encodedMilestones_),
            keccak256(encodedBase_)
        );

        // return
        return encodedMsg_;

    }

    /**************************************

        Invest

     **************************************/

    function invest(
        RequestTypes.InvestRequest calldata _request,
        bytes32 _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {

        // tx.members
        address sender_ = msg.sender;

        // request.members
        uint256 investment_ = _request.investment;
        string memory raiseId_ = _request.raiseId;

        // validate request
        _validateInvestRequest(_request);

        // eip712 encoding
        bytes memory encodedMsg_ = _encodeInvest(
            _request
        );

        // verify message
        LibSignature.verifyMessage(
            EIP712_NAME,
            EIP712_VERSION,
            keccak256(encodedMsg_),
            _message
        );

        // verify signature
        _verifySignature(
            _message,
            _v,
            _r,
            _s
        );

        // collect investment
        LibRaise.collectUSDT(sender_, _request.investment);

        // equity id
        uint256 badgeId_ = LibRaise.convertRaiseToBadge(
            raiseId_
        );

        // increase nonce
        LibNonce.setNonce(sender_, _request.base.nonce);

        // mint badge
        LibRaise.mintBadge(
            badgeId_,
            investment_ / USDT_DECIMALS
        );

        // storage
        LibRaise.saveInvestment(
            raiseId_,
            investment_
        );

        // event
        emit NewInvestment(
            sender_,
            raiseId_,
            investment_,
            _message,
            badgeId_
        );

    }

    function _validateInvestRequest(
        RequestTypes.InvestRequest calldata _request
    ) internal view {

        // tx.members
        address sender_ = msg.sender;
        uint256 now_ = block.timestamp;

        // check replay attack
        uint256 nonce_ = _request.base.nonce;
        if (nonce_ <= LibNonce.getLastNonce(sender_)) {
            revert NonceExpired(sender_, nonce_);
        }

        // check request expiration
        if (now_ > _request.base.expiry) {
            revert RequestExpired(sender_, abi.encode(_request));
        }

        // verify sender
        if (sender_ != _request.base.sender) {
            revert IncorrectSender(sender_);
        }

        // check if fundraising is active (in time)
        if (!LibRaise.isRaiseActive(_request.raiseId)) {
            revert RaiseNotActive(_request.raiseId, now_);
        }

        // verify amount + storage vs ticket size
        uint256 existingInvestment = LibRaise.getInvestment(_request.raiseId, sender_);
        if (existingInvestment + _request.investment > _request.maxTicketSize) {
            revert InvestmentOverLimit(existingInvestment, _request.investment, _request.maxTicketSize);
        }

        // check if the investement does not make the total investment exceed the limit
        uint256 existingTotalInvestment = LibRaise.getTotalInvestment(_request.raiseId);
        uint256 hardcap = LibRaise.getHardCap(_request.raiseId);
        if (existingTotalInvestment + _request.investment > hardcap) {
            revert InvestmentOverHardcap(existingInvestment, _request.investment, hardcap);
        }

    }

    function _encodeInvest(
        RequestTypes.InvestRequest memory _request
    ) internal pure
    returns (bytes memory) {

        // base
        bytes memory encodedBase_ = abi.encode(_request.base);

        // msg
        bytes memory encodedMsg_ = abi.encode(
            INVESTOR_INVEST_TYPEHASH,
            keccak256(bytes(_request.raiseId)),
            _request.investment,
            _request.maxTicketSize,
            keccak256(encodedBase_)
        );

        // return
        return encodedMsg_;

    }

    /**************************************

        Refund funds

     **************************************/

    function refundInvestment(string memory _raiseId) external {

        address sender_ = msg.sender;

        // check if raise is finished already
        if (!LibRaise.isRaiseFinished(_raiseId)) {
            revert RaiseNotFinished(_raiseId);
        }

        // check if raise didn't reach softcap
        if (LibRaise.isSoftcapAchieved(_raiseId)) {
            revert SoftcapAchieved(_raiseId);
        }

        // refund
        LibRaise.refundUSDT(sender_, _raiseId);

    }

    /**************************************

        Internal: Verify signature

     **************************************/

    function _verifySignature(
        bytes32 _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal view {

        // signer of message
        address signer_ = LibSignature.recoverSigner(
            _message,
            _v,
            _r,
            _s
        );

        // validate signer
        if (!LibAccessControl.hasRole(AccessTypes.SIGNER_ROLE, signer_)) {
            revert IncorrectSigner(signer_);
        }

    }

    /**************************************

        View: Convert raise to badge

     **************************************/

    function convertRaiseToBadge(string memory _raiseId) external view
    returns (uint256) {

        // return
        return LibRaise.convertRaiseToBadge(_raiseId);

    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

// OpenZeppelin
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**************************************

    Signature library

**************************************/

library LibSignature {

    // typehashes
    bytes32 constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // errors
    error InvalidMessage(bytes32 verify, bytes32 message);

    /**************************************

        Verify message

     **************************************/

    function verifyMessage(
        bytes32 _nameHash,
        bytes32 _versionHash,
        bytes32 _rawMessage,
        bytes32 _message
    ) internal view {

        // build domain separator
        bytes32 domainSeparatorV4_ = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            _nameHash,
            _versionHash,
            block.chainid,
            address(this)
        ));

        // construct EIP712 message
        bytes32 toVerify_ = ECDSA.toTypedDataHash(domainSeparatorV4_, _rawMessage);

        // verify computation against original
        if (toVerify_ != _message) {
            revert InvalidMessage(toVerify_, _message);
        }

    }

    /**************************************

        Recover signer

     **************************************/

    function recoverSigner(
        bytes32 _data,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal pure returns (address) {

        // recover EIP712 signer using provided vrs
        address signer_ = ECDSA.recover(
            _data,
            _v,
            _r,
            _s
        );

        // return signer
        return signer_;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

library AccessTypes {

    // roles
    bytes32 constant SIGNER_ROLE = keccak256("IS SIGNER");

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

// OpenZeppelin imports
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

/**************************************

    AccessControl library

    ------------------------------

    Diamond storage containing access control data

 **************************************/

library LibAccessControl {

    // storage pointer
    bytes32 constant ACCESS_CONTROL_STORAGE_POSITION = keccak256("angelblock.access.control");
    bytes32 constant ADMIN_ROLE = 0x0;

    // structs: data containers
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }
    struct AccessControlStorage {
        mapping(bytes32 => RoleData) roles;
        bool initialized;
    }

    // diamond storage getter
    function accessStorage() internal pure
    returns (AccessControlStorage storage acs) {

        // declare position
        bytes32 position = ACCESS_CONTROL_STORAGE_POSITION;

        // set slot to position
        assembly {
            acs.slot := position
        }

        // explicit return
        return acs;

    }

    // events
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    // errors
    error CannotSetAdminForAdmin();
    error CanOnlyRenounceSelf();
    error OneTimeFunction();

    // modifiers
    modifier onlyRole(bytes32 _role) {

        // check role
        if (!hasRole(_role, msg.sender)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(msg.sender),
                        " is missing role ",
                        Strings.toHexString(uint256(_role), 32)
                    )
                )
            );
        }
        _;

    }
    modifier oneTime() {

        // storage
        AccessControlStorage storage acs = accessStorage();

        // initialize
        if (!acs.initialized) {
            acs.initialized = true;
            _;
        } else {
            revert OneTimeFunction();
        }

    }

    // diamond storage getter: has role
    function hasRole(bytes32 _role, address _account) internal view 
    returns (bool) {

        // return
        return accessStorage().roles[_role].members[_account];

    }

    // diamond storage setter: set role
    function createAdmin(address _account) internal oneTime() {

        // set role
        accessStorage().roles[ADMIN_ROLE].members[_account] = true;

    }

    // diamond storage getter: has admin role
    function getRoleAdmin(bytes32 _role) internal view 
    returns (bytes32) {

        // return
        return accessStorage().roles[_role].adminRole;

    }

    // diamond storage setter: set admin role
    function setRoleAdmin(bytes32 _role, bytes32 _adminRole) internal onlyRole(ADMIN_ROLE) {

        // accept each role except admin
        if (_role != ADMIN_ROLE) accessStorage().roles[_role].adminRole = _adminRole;
        else revert CannotSetAdminForAdmin();

    }

    /**************************************

        Grant role

     **************************************/

    function grantRole(bytes32 _role, address _account) internal onlyRole(getRoleAdmin(_role)) {

        // grant
        _grantRole(_role, _account);

    }

    /**************************************

        Revoke role

     **************************************/

    function revokeRole(bytes32 _role, address _account) internal onlyRole(getRoleAdmin(_role)) {

        // revoke
        _revokeRole(_role, _account);

    }

    /**************************************

        Renounce role

     **************************************/

    function renounceRole(bytes32 role, address account) internal {

        // check sender
        if (account != msg.sender) {
            revert CanOnlyRenounceSelf();
        }

        // revoke
        _revokeRole(role, account);

    }

    /**************************************

        Low level: grant

     **************************************/

    function _grantRole(bytes32 _role, address _account) private {

        // check if not have role already
        if (!hasRole(_role, _account)) {

            // grant role
            accessStorage().roles[_role].members[_account] = true;

            // event
            emit RoleGranted(_role, _account, msg.sender);

        }

    }

    /**************************************

        Low level: revoke

     **************************************/

    function _revokeRole(bytes32 _role, address _account) private {

        // check if have role
        if (hasRole(_role, _account)) {

            // revoke role
            accessStorage().roles[_role].members[_account] = false;

            // event
            emit RoleRevoked(_role, _account, msg.sender);

        }

    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

import { BaseTypes } from "../structs/BaseTypes.sol";

/**************************************

    Milestone library

    ------------------------------

    Diamond storage containing milestones data

 **************************************/

library LibMilestone {

    // storage pointer
    bytes32 constant MILESTONE_STORAGE_POSITION = keccak256("angelblock.fundraising.milestone");

    // errors
    error MaximumMilestonesExceeded(uint256 milestones);

    // structs: data containers
    struct MilestoneStorage {
        mapping (string => BaseTypes.Milestone[]) milestones;
    }

    // diamond storage getter
    function milestoneStorage() internal pure
    returns (MilestoneStorage storage ms) {

        // declare position
        bytes32 position = MILESTONE_STORAGE_POSITION;

        // set slot to position
        assembly {
            ms.slot := position
        }

        // explicit return
        return ms;

    }

    // diamond storage getter: milestone
    function getMilestone(
        string memory _raiseId,
        uint256 _number
    ) internal view
    returns (BaseTypes.Milestone memory) {

        // return
        return milestoneStorage().milestones[_raiseId][_number];

    }

    // diamond storage getter: milestones count
    function getMilestoneCount(string memory _raiseId) internal view
    returns (uint256) {

        // return
        return milestoneStorage().milestones[_raiseId].length;

    }

    // diamond storage setter: milestones
    function saveMilestones(
        string memory _raiseId,
        BaseTypes.Milestone[] calldata _milestones
    ) internal {

        // declare milestones limit
        uint8 MILESTONES_LIMIT = 100;

        // milestone length
        uint256 milestonesLength = _milestones.length;

        // revert on limit
        if (milestonesLength > MILESTONES_LIMIT) {
            revert MaximumMilestonesExceeded(milestonesLength);
        }

        // get storage
        MilestoneStorage storage ms = milestoneStorage();

        // save milestones
        for (uint256 i = 0; i < milestonesLength; i++) {
            ms.milestones[_raiseId].push(_milestones[i]);
        }

    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

// OpenZeppelin imports
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Local imports
import { BaseTypes } from "../structs/BaseTypes.sol";
import { StateTypes } from "../structs/StateTypes.sol";
import { LibAppStorage } from "./LibAppStorage.sol";
import { IEquityBadge } from "../../interfaces/IEquityBadge.sol";

/**************************************

    Raise library

    ------------------------------

    Diamond storage containing raise data

 **************************************/

library LibRaise {
    using SafeERC20 for IERC20;

    // storage pointer
    bytes32 constant RAISE_STORAGE_POSITION = keccak256("angelblock.fundraising.raise");

    // structs: data containers
    struct RaiseStorage {
        mapping (string => BaseTypes.Raise) raises;
        mapping (string => BaseTypes.Vested) vested;
        mapping (string => StateTypes.ProjectInvestInfo) investInfo;
    }

    // diamond storage getter
    function raiseStorage() internal pure
    returns (RaiseStorage storage rs) {

        // declare position
        bytes32 position = RAISE_STORAGE_POSITION;

        // set slot to position
        assembly {
            rs.slot := position
        }

        // explicit return
        return rs;

    }

    // diamond storage getter: vested.erc20
    function getVestedERC20(string memory _raiseId) internal view
    returns (address) {

        // return
        return raiseStorage().vested[_raiseId].erc20;

    }

    // diamond storage getter: vested.ether
    function getVestedEther(string memory _raiseId) internal view
    returns (uint256) {

        // return
        return raiseStorage().vested[_raiseId].amount;

    }

    // diamond storage setter: raise
    function saveRaise(
        string memory _raiseId,
        BaseTypes.Raise memory _raise,
        BaseTypes.Vested memory _vested
    ) internal {

        // get storage
        RaiseStorage storage rs = raiseStorage();

        // save raise
        rs.raises[_raiseId] = _raise;
        rs.vested[_raiseId] = _vested;

    }

    // diamond storage getter: investment
    function getInvestment(
        string memory _raiseId,
        address _account
    ) internal view
    returns (uint256) {

        // return
        return raiseStorage().investInfo[_raiseId].invested[_account];

    }

    // diamond storage getter: total investment
    function getTotalInvestment(
        string memory _raiseId
    ) internal view
    returns (uint256) {

        // return
        return raiseStorage().investInfo[_raiseId].raised;

    }

    // diamond storage setter: investment
    function saveInvestment(
        string memory _raiseId,
        uint256 _investment
    ) internal {

        // tx.members
        address sender_ = msg.sender;

        // get storage
        RaiseStorage storage rs = raiseStorage();

        // save investment
        rs.investInfo[_raiseId].raised += _investment;
        rs.investInfo[_raiseId].invested[sender_] += _investment;

    }

    // diamond storage getter: hardcap
    function getHardCap(
        string memory _raiseId
    ) internal view returns (uint256) {

        // return
        return raiseStorage().raises[_raiseId].hardcap;

    }

    // errors
    error RaiseAlreadyExists(string raiseId);
    error RaiseDoesNotExists(string raiseId);
    error NotEnoughBalanceForInvestment(address sender, uint256 investment);
    error NotEnoughAllowanceForInvestment(address sender, uint256 investment);

    /**************************************

        Verify raise

     **************************************/

    function verifyRaise(string memory _raiseId) internal view {

        // get storage
        RaiseStorage storage rs = raiseStorage();

        // check existence
        if (bytes(rs.raises[_raiseId].raiseId).length != 0) {
            revert RaiseAlreadyExists(_raiseId);
        }

    }

    /**************************************

        Convert raise id to badge id

     **************************************/

    function convertRaiseToBadge(string memory _raiseId) internal view
    returns (uint256) {

        // existence check
        if (bytes(raiseStorage().raises[_raiseId].raiseId).length == 0) {
            revert RaiseDoesNotExists(_raiseId);
        }

        // return
        return uint256(keccak256(abi.encode(_raiseId)));

    }

    /**************************************

        Mint badge

     **************************************/

    function mintBadge(
        uint256 _badgeId,
        uint256 _investment
    ) internal {

        // tx.members
        address sender_ = msg.sender;

        // get badge
        IEquityBadge badge = LibAppStorage.getBadge();

        // erc1155 bytes conversion
        bytes memory data_ = abi.encode(_badgeId);

        // delegate on behalf
        badge.delegateOnBehalf(sender_, sender_, data_);

        // mint equity badge
        badge.mint(sender_, _badgeId, _investment, data_);

    }

    /**************************************

        Balance of badge

     **************************************/

    function badgeBalanceOf(
        address _owner,
        uint256 _badgeId
    ) internal view
    returns (uint256) {

        // return
        return LibAppStorage.getBadge().balanceOf(
            _owner,
            _badgeId
        );

    }

    /**************************************

        Total supply of badge

     **************************************/

    function badgeTotalSupply(uint256 _badgeId) internal view
    returns (uint256) {

        // return
        return LibAppStorage.getBadge().totalSupply(_badgeId);

    }

    /**************************************

        Collect USDT for investment

     **************************************/

    function collectUSDT(address _sender, uint256 _investment) internal {

        // tx.members
        address self_ = address(this);
        
        // get USDT contract
        IERC20 usdt_ = LibAppStorage.getUSDT();

        // check balance
        if (usdt_.balanceOf(_sender) < _investment)
            revert NotEnoughBalanceForInvestment(_sender, _investment);

        // check approval
        if (usdt_.allowance(_sender, address(this)) < _investment)
            revert NotEnoughAllowanceForInvestment(_sender, _investment);

        // transfer
        usdt_.safeTransferFrom(
            _sender,
            self_,
            _investment
        );

    } 

    /**************************************

        Check if given raise is still active

     **************************************/

    function isRaiseActive(string memory _raiseId) internal view
    returns (bool) {
        
        // tx.members
        uint256 now_ = block.timestamp;

        // get raise
        BaseTypes.Raise storage raise_ = raiseStorage().raises[_raiseId];

        // final check
        return raise_.start <= now_ && now_ <= raise_.end;

    }

    /**************************************

        Check if given raise finished already

     **************************************/

    function isRaiseFinished(string memory _raiseId) internal view
    returns (bool) {
        return raiseStorage().raises[_raiseId].end < block.timestamp;
    }

    /**************************************

        Check if given raise achieved softcap

     **************************************/

    function isSoftcapAchieved(string memory _raiseId) internal view
    returns (bool) {
        RaiseStorage storage rs = raiseStorage();
        return rs.raises[_raiseId].softcap <= rs.investInfo[_raiseId].raised;
    }

    /**************************************

        Make raise refund for given wallet

     **************************************/

    function refundUSDT(
        address _sender,
        string memory _raiseId
    ) internal {

        // prepare for transfer
        RaiseStorage storage rs = raiseStorage();
        uint256 investment_ = rs.investInfo[_raiseId].invested[_sender];
        rs.investInfo[_raiseId].invested[_sender] = 0;

        // transfer
        LibAppStorage.getUSDT().safeTransfer(
            _sender,
            investment_
        );

    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

/**************************************

    Nonce library

    ------------------------------

    Diamond storage containing nonces

 **************************************/

library LibNonce {

    // storage pointer
    bytes32 constant NONCE_STORAGE_POSITION = keccak256("angelblock.fundraising.nonce");

    // structs: data containers
    struct NonceStorage {
        mapping (address => uint256) nonces;
    }

    // diamond storage getter
    function nonceStorage() internal pure
    returns (NonceStorage storage ns) {

        // declare position
        bytes32 position = NONCE_STORAGE_POSITION;

        // set slot to position
        assembly {
            ns.slot := position
        }

        // explicit return
        return ns;

    }

    // diamond storage getter: nonces
    function getLastNonce(address _account) internal view
    returns (uint256) {

        // return
        return nonceStorage().nonces[_account];

    }

    /**************************************

        Increment nonce

     **************************************/

    function setNonce(address _account, uint256 _nonce) internal {

        // get storage
        NonceStorage storage ns = nonceStorage();

        // set nonce
        ns.nonces[_account] = _nonce;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

// Local imports
import { BaseTypes } from "../structs/BaseTypes.sol";
import { RequestTypes } from "../structs/RequestTypes.sol";

/**************************************

    Raise facet interface

**************************************/

interface IRaiseFacet {

    // events
    event NewRaise(address sender, BaseTypes.Raise raise, BaseTypes.Milestone[] milestones, bytes32 message);
    event NewInvestment(address sender, string raiseId, uint256 investment, bytes32 message, uint256 data);

    // errors
    error NonceExpired(address sender, uint256 nonce);
    error RequestExpired(address sender, bytes request);
    error IncorrectSender(address sender);
    error IncorrectSigner(address signer);
    error InvalidRaiseId(string raiseId);
    error InvalidMilestoneCount(BaseTypes.Milestone[] milestones);
    error InvalidMilestoneStartEnd(uint256 start, uint256 end);
    error NotEnoughAllowance(address sender, address spender, uint256 amount);
    error IncorrectAmount(uint256 amount);
    error InvestmentOverLimit(uint256 existingInvestment, uint256 newInvestment, uint256 maxTicketSize);
    error InvestmentOverHardcap(uint256 existingInvestment, uint256 newInvestment, uint256 hardcap);
    error RaiseNotActive(string raiseId, uint256 currentTime);
    error RaiseNotFinished(string raiseId);
    error SoftcapAchieved(string raiseId);

    /**************************************

        Create new raise

     **************************************/

    function createRaise(
        RequestTypes.CreateRaiseRequest calldata _request,
        bytes32 _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**************************************

        Invest

     **************************************/

    function invest(
        RequestTypes.InvestRequest calldata _request,
        bytes32 _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**************************************

        Refund funds

     **************************************/

    function refundInvestment(string memory _raiseId) external;

    /**************************************

        View: Convert raise to badge

     **************************************/

    function convertRaiseToBadge(string memory _raiseId) external view
    returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

import { BaseTypes } from "./BaseTypes.sol";

library RequestTypes {

    // structs: requests
    struct BaseRequest {
        address sender;
        uint256 expiry;
        uint256 nonce;
    }
    struct CreateRaiseRequest {
        BaseTypes.Raise raise;
        BaseTypes.Vested vested;
        BaseTypes.Milestone[] milestones;
        BaseRequest base;
    }
    struct InvestRequest {
        string raiseId;
        uint256 investment;
        uint256 maxTicketSize;
        BaseRequest base;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

library BaseTypes {

    // enums: low level
    enum SimpleVote {
        NO,
        YES
    }
    enum VotingStatus {
        ACCEPTED,
        REJECTED,
        NOT_RESOLVED
    }

    // structs: low level
    struct Raise {
        string raiseId;
        uint256 hardcap;
        uint256 softcap;
        uint256 start;
        uint256 end;
    }
    struct Vested {
        address erc20;
        uint256 amount;
    }
    struct Milestone {
        uint256 number;
        uint256 deadline;
        bytes32 hashedDescription;
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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

import { IERC1155Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

/**************************************

    EquityBadge interface

 **************************************/

interface IEquityBadge is IERC1155Upgradeable {

    // mint from fundraising
    function mint(
        address _sender, uint256 _projectId, uint256 _amount, bytes memory _data
    ) external;

    // delegate on behalf from fundraising
    function delegateOnBehalf(
        address _account, address _delegatee, bytes memory _data
    ) external;

    // total supply
    function totalSupply(uint256 _projectId) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IEquityBadge } from "../../interfaces/IEquityBadge.sol";
import { IVestedGovernor } from "../../interfaces/IVestedGovernor.sol";

/**************************************

    AppStorage library

    ------------------------------

    A specialized version of Diamond Storage is AppStorage.
    This pattern is used to more conveniently and easily share state variables between facets.

 **************************************/

library LibAppStorage {

    // structs: data containers
    struct AppStorage {
        IERC20 usdt;
        IEquityBadge equityBadge;
        IVestedGovernor vestedGovernor;
    }

    // diamond storage getter
    function appStorage() internal pure
    returns (AppStorage storage s) {

        // set slot 0 and return
        assembly {
            s.slot := 0
        }

        // explicit return
        return s;

    }

    /**************************************

        Get USDT

     **************************************/

    function getUSDT() internal view
    returns (IERC20) {

        // return
        return appStorage().usdt;

    }

    /**************************************

        Get badge

     **************************************/

    function getBadge() internal view
    returns (IEquityBadge) {

        // return
        return appStorage().equityBadge;

    }

    /**************************************

        Get vested governor

     **************************************/

    function getGovernor() internal view
    returns (IVestedGovernor) {

        // return
        return appStorage().vestedGovernor;

    }

    /**************************************

        Get timelock

     **************************************/

    function getTimelock() internal view
    returns (address) {

        // return
        return appStorage().vestedGovernor.timelock();

    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

library StateTypes {

    // structs: state tracking
    struct Voting {
        uint256 proposalId;
        bool unlocked;
    }
    struct ProjectInvestInfo {
        uint256 raised;
        mapping (address => uint256) invested;
    }
    struct InvestorVoteInfo {
        mapping (uint256 => bool) voted;
        mapping (uint256 => bool) claimed;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
interface IERC165Upgradeable {
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
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

import { IGovernorTimelock } from "../oz/interfaces/IGovernorTimelock.sol";

/**************************************

    VestedGovernor interface

 **************************************/

abstract contract IVestedGovernor is IGovernorTimelock {}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    @dev AB: OZ override
    @dev Modification scope: inheriting from modified Governor

    ------------------------------

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

 **************************************/

import { IGovernor } from "./IGovernor.sol";

/**
 * @dev Extension of the {IGovernor} for timelock supporting modules.
 *
 * _Available since v4.3._
 */
abstract contract IGovernorTimelock is IGovernor {
    event ProposalQueued(uint256 proposalId, uint256 eta);

    function timelock() public view virtual returns (address);

    function proposalEta(uint256 proposalId) public view virtual returns (uint256);

    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual returns (uint256 proposalId);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    @dev AB: OZ override
    @dev Modification scope: getVotes, propose, castVote, castVoteWithReason, castVoteBySig

    ------------------------------

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

 **************************************/

// OZ imports
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface of the {Governor} core.
 *
 * _Available since v4.3._
 */
abstract contract IGovernor is IERC165 {
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /**
     * @dev Emitted when a proposal is created.
     */
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    /**
     * @dev Emitted when a proposal is canceled.
     */
    event ProposalCanceled(uint256 proposalId);

    /**
     * @dev Emitted when a proposal is executed.
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * @dev Emitted when a vote is cast without params.
     *
     * Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
     */
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason);

    /**
     * @dev Emitted when a vote is cast with params.
     *
     * Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
     * `params` are additional encoded parameters. Their intepepretation also depends on the voting module used.
     */
    event VoteCastWithParams(
        address indexed voter,
        uint256 proposalId,
        uint8 support,
        uint256 weight,
        string reason,
        bytes params
    );

    /**
     * @notice module:core
     * @dev Name of the governor instance (used in building the ERC712 domain separator).
     */
    function name() public view virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Version of the governor instance (used in building the ERC712 domain separator). Default: "1"
     */
    function version() public view virtual returns (string memory);

    /**
     * @notice module:voting
     * @dev A description of the possible `support` values for {castVote} and the way these votes are counted, meant to
     * be consumed by UIs to show correct vote options and interpret the results. The string is a URL-encoded sequence of
     * key-value pairs that each describe one aspect, for example `support=bravo&quorum=for,abstain`.
     *
     * There are 2 standard keys: `support` and `quorum`.
     *
     * - `support=bravo` refers to the vote options 0 = Against, 1 = For, 2 = Abstain, as in `GovernorBravo`.
     * - `quorum=bravo` means that only For votes are counted towards quorum.
     * - `quorum=for,abstain` means that both For and Abstain votes are counted towards quorum.
     *
     * If a counting module makes use of encoded `params`, it should  include this under a `params` key with a unique
     * name that describes the behavior. For example:
     *
     * - `params=fractional` might refer to a scheme where votes are divided fractionally between for/against/abstain.
     * - `params=erc721` might refer to a scheme where specific NFTs are delegated to vote.
     *
     * NOTE: The string can be decoded by the standard
     * https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams[`URLSearchParams`]
     * JavaScript class.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Hashing function used to (re)build the proposal id from the proposal details..
     */
    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public pure virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Current state of a proposal, following Compound's convention
     */
    function state(uint256 proposalId) public view virtual returns (ProposalState);

    /**
     * @notice module:core
     * @dev Block number used to retrieve user's votes and quorum. As per Compound's Comp and OpenZeppelin's
     * ERC20Votes, the snapshot is performed at the end of this block. Hence, voting for this proposal starts at the
     * beginning of the following block.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Block number at which votes close. Votes close at the end of this block, so it is possible to cast a vote
     * during this block.
     */
    function proposalDeadline(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of block, between the proposal is created and the vote starts. This can be increased to
     * leave time for users to buy voting power, or delegate it, before the voting of a proposal starts.
     */
    function votingDelay() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of blocks, between the vote start and vote ends.
     *
     * NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
     * duration compared to the voting delay.
     */
    function votingPeriod() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Minimum number of cast voted required for a proposal to be successful.
     *
     * Note: The `blockNumber` parameter corresponds to the snapshot used for counting vote. This allows to scale the
     * quorum depending on values such as the totalSupply of a token at this block (see {ERC20Votes}).
     */
    function quorum(uint256 blockNumber) public view virtual returns (uint256);

    /**************************************

        @notice Override of OZ getVotes

        ------------------------------

        @dev AB: added data arg
        @dev Example usage for ERC20: empty (value: 0x0)
        @dev Example usage for ERC1155: tokenId (type: bytes<uint256>)

        ------------------------------

        @param account Target account to get votes for
        @param blockNumber Number of block to get votes for
        @param data Bytes encoding optional parameters

     **************************************/

    /**
     * @notice module:reputation
     * @dev Voting power of an `account` at a specific `blockNumber`.
     *
     * Note: this can be implemented in a number of ways, for example by reading the delegated balance from one (or
     * multiple), {ERC20Votes} tokens.
     */
    function getVotes(
        address account, 
        uint256 blockNumber, 
        bytes memory data
    ) public view virtual returns (uint256);

    /**
     * @notice module:reputation
     * @dev Voting power of an `account` at a specific `blockNumber` given additional encoded parameters.
     */
    function getVotesWithParams(
        address account,
        uint256 blockNumber,
        bytes memory params
    ) public view virtual returns (uint256);

    /**
     * @notice module:voting
     * @dev Returns either `account` has cast a vote on `proposalId`.
     */
    function hasVoted(uint256 proposalId, address account) public view virtual returns (bool);

    /**************************************

        @notice Override of OZ propose

        ------------------------------

        @dev AB: added data arg
        @dev Example usage for ERC20: empty (value: 0x0)
        @dev Example usage for ERC1155: tokenId (type: bytes<uint256>)

        ------------------------------

        @param targets List of addresses for delegatecalls
        @param values List of ether amounts for delegatecalls
        @param calldatas List of encoded functions with arguments
        @param description Description of proposal
        @param data Bytes encoding optional parameters

     **************************************/

    /**
     * @dev Create a new proposal. Vote start {IGovernor-votingDelay} blocks after the proposal is created and ends
     * {IGovernor-votingPeriod} blocks after the voting starts.
     *
     * Emits a {ProposalCreated} event.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description,
        bytes memory data
    ) public virtual returns (uint256 proposalId);

    /**
     * @dev Execute a successful proposal. This requires the quorum to be reached, the vote to be successful, and the
     * deadline to be reached.
     *
     * Emits a {ProposalExecuted} event.
     *
     * Note: some module can modify the requirements for execution, for example by adding an additional timelock.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual returns (uint256 proposalId);

    /**************************************

        @notice Override of OZ castVote

        ------------------------------

        @dev AB: added data arg
        @dev Example usage for ERC20: empty (value: 0x0)
        @dev Example usage for ERC1155: tokenId (type: bytes<uint256>)

        ------------------------------

        @param proposalId Number of proposal
        @param support Decision of voting
        @param data Bytes encoding optional parameters

     **************************************/

    /**
     * @dev Cast a vote
     *
     * Emits a {VoteCast} event.
     */
    function castVote(uint256 proposalId, uint8 support, bytes memory data) public virtual returns (uint256 balance);

    /**************************************

        @notice Override of OZ castVoteWithReason

        ------------------------------

        @dev AB: added data arg
        @dev Example usage for ERC20: empty (value: 0x0)
        @dev Example usage for ERC1155: tokenId (type: bytes<uint256>)

        ------------------------------

        @param proposalId Number of proposal
        @param support Decision of voting
        @param reason String for the reason
        @param data Bytes encoding optional parameters

     **************************************/

    /**
     * @dev Cast a vote with a reason
     *
     * Emits a {VoteCast} event.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory data
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason and additional encoded parameters
     *
     * Emits a {VoteCast} or {VoteCastWithParams} event depending on the length of params.
     */
    function castVoteWithReasonAndParams(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params
    ) public virtual returns (uint256 balance);

    /**************************************

        @notice Override of OZ castVoteBySig

        ------------------------------

        @dev AB: added data arg
        @dev Example usage for ERC20: empty (value: 0x0)
        @dev Example usage for ERC1155: tokenId (type: bytes<uint256>)

        ------------------------------

        @param proposalId Number of proposal
        @param support Decision of voting
        @param data Bytes encoding optional parameters
        @param v Part of signature
        @param r Part of signature
        @param s Part of signature

     **************************************/

    /**
     * @dev Cast a vote using the user's cryptographic signature.
     *
     * Emits a {VoteCast} event.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        bytes memory data,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason and additional encoded parameters using the user's cryptographic signature.
     *
     * Emits a {VoteCast} or {VoteCastWithParams} event depending on the length of params.
     */
    function castVoteWithReasonAndParamsBySig(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256 balance);
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