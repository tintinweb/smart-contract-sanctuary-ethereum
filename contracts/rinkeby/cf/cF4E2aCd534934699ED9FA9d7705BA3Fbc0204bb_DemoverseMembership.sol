// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IDemoverseMembership.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";
import "./services/MembershipDisable.sol";
import "./services/ERC721Enumerable.sol";
import "./services/Funds.sol";
import "./services/GrantKeys.sol";
import "./services/Keys.sol";
import "./services/MembershipCore.sol";
import "./services/MembershipMetadata.sol";
import "./services/Purchase.sol";
import "./services/Refunds.sol";
import "./services/Transfer.sol";
import "./services/Roles.sol";
import "./services/ConvenienceOwnable.sol";
import "./services/Royalties.sol";

contract DemoverseMembership is
    Initializable,
    ERC165StorageUpgradeable,
    Roles,
    Funds,
    MembershipDisable,
    MembershipCore,
    Keys,
    MembershipMetadata,
    ERC721Enumerable,
    GrantKeys,
    Purchase,
    Transfer,
    Refunds,
    ConvenienceOwnable,
    Royalties
{
    function initialize(
        address payable _membershipCreator,
        uint256 _expirationDuration,
        address _tokenAddress,
        uint256 _keyPrice,
        uint256 _maxNumberOfKeys,
        string calldata _membershipName,
        uint256 _royaltyPercent // royalty percentage
    ) public initializer {
        Funds._initializeFunds(_tokenAddress);
        MembershipDisable._initializeDisable();
        MembershipCore._initializeMembershipCore(
            _membershipCreator,
            _expirationDuration,
            _keyPrice,
            _maxNumberOfKeys
        );
        MembershipMetadata._initializeMembershipMetadata(_membershipName);
        ERC721Enumerable._initializeERC721Enumerable();
        Refunds._initializeRefunds();
        Roles._initializeRoles(_membershipCreator);
        ConvenienceOwnable._initializeConvenienceOwnable(_membershipCreator);
        Royalties._initializeRoyalties(_royaltyPercent);
        _registerInterface(0x80ac58cd);
    }

    receive() external payable {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721Enumerable,
            MembershipMetadata,
            AccessControlUpgradeable,
            ERC165StorageUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Roles.sol";
import "./MembershipDisable.sol";
import "./Keys.sol";
import "./Funds.sol";
import "./MembershipCore.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract Transfer is Roles, Funds, MembershipCore, Keys {
    using AddressUpgradeable for address;

    event TransferFeeChanged(uint256 transferFeeBasisPoints);

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    uint256 public transferFeeBasisPoints;

    function shareKey(
        address _to,
        uint256 _tokenId,
        uint256 _timeShared
    ) public {
        _onlyIfAlive();
        _onlyKeyManagerOrApproved(_tokenId);
        require(
            transferFeeBasisPoints < BASIS_POINTS_DEN,
            "KEY_TRANSFERS_DISABLED"
        );
        require(_to != address(0), "INVALID_ADDRESS");
        address keyOwner = _ownerOf[_tokenId];
        _hasValidKey(keyOwner);
        require(keyOwner != _to, "TRANSFER_TO_SELF");

        Key memory fromKey = getKeyByOwner(keyOwner);
        Key memory toKey = getKeyByOwner(_to);
        uint256 idTo = toKey.tokenId;
        uint256 time;

        uint256 timeRemaining = fromKey.expirationTimestamp - block.timestamp;
        uint256 fee = getTransferFee(keyOwner, _timeShared);
        uint256 timePlusFee = _timeShared + fee;

        if (timePlusFee < timeRemaining) {
            time = _timeShared;
            _timeMachine(_tokenId, timePlusFee, false);
        } else {
            fee = getTransferFee(keyOwner, timeRemaining);
            time = timeRemaining - fee;
            _updateKeyExpirationTimestamp(keyOwner, block.timestamp);
            emit ExpireKey(_tokenId);
        }

        if (idTo == 0) {
            idTo = _createNewKey(_to, address(0), block.timestamp);
        } else if (toKey.expirationTimestamp <= block.timestamp) {
            _setKeyManagerOf(toKey.tokenId, address(0));
        }

        _timeMachine(idTo, time, true);

        emit Transfer(keyOwner, _to, idTo);

        require(
            _checkOnERC721Received(keyOwner, _to, toKey.tokenId, ""),
            "NON_COMPLIANT_ERC721_RECEIVER"
        );
    }

    function transferFrom(
        address _from,
        address _recipient,
        uint256 _tokenId
    ) public {
        _onlyIfAlive();
        _hasValidKey(_from);
        _onlyKeyManagerOrApproved(_tokenId);
        require(ownerOf(_tokenId) == _from, "TRANSFER_FROM: NOT_KEY_OWNER");
        require(
            transferFeeBasisPoints < BASIS_POINTS_DEN,
            "KEY_TRANSFERS_DISABLED"
        );
        require(_recipient != address(0), "INVALID_ADDRESS");
        require(_from != _recipient, "TRANSFER_TO_SELF");

        _timeMachine(_tokenId, getTransferFee(_from, 0), false);

        Key memory fromKey = getKeyByOwner(_from);
        Key memory toKey = getKeyByOwner(_recipient);
        uint256 previousExpiration = toKey.expirationTimestamp;

        if (toKey.tokenId == 0) {
            _transferKey(_tokenId, _recipient, fromKey.expirationTimestamp);

            _clearApproval(_tokenId);
        } else if (previousExpiration <= block.timestamp) {
            _updateKeyExpirationTimestamp(
                _recipient,
                fromKey.expirationTimestamp
            );

            _updateKeyTokenId(_recipient, _tokenId);

            _setKeyManagerOf(_tokenId, address(0));
            _recordOwner(_recipient, _tokenId);
        } else {
            require(
                expirationDuration != type(uint256).max,
                "NON_EXPIRING_KEY"
            );
            _updateKeyExpirationTimestamp(
                _recipient,
                fromKey.expirationTimestamp +
                    previousExpiration -
                    block.timestamp
            );
        }

        _expireKey(_from);

        emit Transfer(_from, _recipient, _tokenId);
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        uint256 maxTimeToSend = _value * expirationDuration;
        Key memory fromKey = getKeyByOwner(msg.sender);
        uint256 timeRemaining = fromKey.expirationTimestamp - block.timestamp;
        if (maxTimeToSend < timeRemaining) {
            shareKey(_to, fromKey.tokenId, maxTimeToSend);
        } else {
            transferFrom(msg.sender, _to, fromKey.tokenId);
        }

        return true;
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public {
        transferFrom(_from, _to, _tokenId);
        require(
            _checkOnERC721Received(_from, _to, _tokenId, _data),
            "NON_COMPLIANT_ERC721_RECEIVER"
        );
    }

    function updateTransferFee(uint256 _transferFeeBasisPoints) external {
        _onlyMembershipManager();
        emit TransferFeeChanged(_transferFeeBasisPoints);
        transferFeeBasisPoints = _transferFeeBasisPoints;
    }

    function getTransferFee(address _keyOwner, uint256 _time)
        public
        view
        returns (uint256)
    {
        if (!getHasValidKey(_keyOwner)) {
            return 0;
        } else {
            Key memory key = getKeyByOwner(_keyOwner);
            uint256 timeToTransfer;
            uint256 fee;
            if (_time == 0) {
                timeToTransfer = key.expirationTimestamp - block.timestamp;
            } else {
                timeToTransfer = _time;
            }
            fee = (timeToTransfer * transferFeeBasisPoints) / BASIS_POINTS_DEN;
            return fee;
        }
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        bytes4 retval = IERC721ReceiverUpgradeable(to).onERC721Received(
            msg.sender,
            from,
            tokenId,
            _data
        );
        return (retval == _ERC721_RECEIVED);
    }

    uint256[1000] private __safe_upgrade_gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Royalties {
    address royaltyReceiver;
    uint256 public royaltyPercent;

    function _initializeRoyalties(
        uint256 _royaltyPercent
    ) internal {
        royaltyReceiver = msg.sender;
        royaltyPercent = _royaltyPercent;
    }

    function royaltyInfo(
        // uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        return (royaltyReceiver, calculateRoyalty(_salePrice));
    }

    // calculate royalty
    function calculateRoyalty(uint256 _salePrice)
        public
        view
        returns (uint256)
    {
        return (_salePrice * royaltyPercent) / 100;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

contract Roles is AccessControlUpgradeable {
  // roles
  bytes32 public constant MEMBERSHIP_MANAGER_ROLE = keccak256("MEMBERSHIP_MANAGER");
  bytes32 public constant KEY_GRANTER_ROLE = keccak256("KEY_GRANTER");

  // events
  event MembershipManagerAdded(address indexed account);
  event MembershipManagerRemoved(address indexed account);
  event KeyGranterAdded(address indexed account);
  event KeyGranterRemoved(address indexed account);

  // initializer
  function _initializeRoles(address sender) internal {
    _setRoleAdmin(MEMBERSHIP_MANAGER_ROLE, MEMBERSHIP_MANAGER_ROLE);

    _setRoleAdmin(KEY_GRANTER_ROLE, MEMBERSHIP_MANAGER_ROLE);

    if (!isMembershipManager(sender)) {
      _setupRole(MEMBERSHIP_MANAGER_ROLE, sender);  
    }
    if (!isKeyGranter(sender)) {
      _setupRole(KEY_GRANTER_ROLE, sender);
    }
  }

  function _onlyMembershipManager() 
  internal 
  view
  {
    require( hasRole(MEMBERSHIP_MANAGER_ROLE, msg.sender), 'ONLY_MEMBERSHIP_MANAGER');
  }

  function isMembershipManager(address account) public view returns (bool) {
    return hasRole(MEMBERSHIP_MANAGER_ROLE, account);
  }

  function addMembershipManager(address account) public {
    _onlyMembershipManager();
    grantRole(MEMBERSHIP_MANAGER_ROLE, account);
    emit MembershipManagerAdded(account);
  }

  function renounceMembershipManager() public {
    renounceRole(MEMBERSHIP_MANAGER_ROLE, msg.sender);
    emit MembershipManagerRemoved(msg.sender);
  }

  function isKeyGranter(address account) public view returns (bool) {
    return hasRole(KEY_GRANTER_ROLE, account);
  }

  function addKeyGranter(address account) public {
    _onlyMembershipManager();
    grantRole(KEY_GRANTER_ROLE, account);
    emit KeyGranterAdded(account);
  }

  function revokeKeyGranter(address _granter) public {
    _onlyMembershipManager();
    revokeRole(KEY_GRANTER_ROLE, _granter);
    emit KeyGranterRemoved(_granter);
  }

  uint256[1000] private __safe_upgrade_gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Keys.sol";
import "./MembershipCore.sol";
import "./Roles.sol";
import "./Funds.sol";

contract Refunds is Roles, Funds, MembershipCore, Keys {
    uint256 public refundPenaltyBasisPoints;

    uint256 public freeTrialLength;

    event CancelKey(
        uint256 indexed tokenId,
        address indexed owner,
        address indexed sendTo,
        uint256 refund
    );

    event RefundPenaltyChanged(
        uint256 freeTrialLength,
        uint256 refundPenaltyBasisPoints
    );

    function _initializeRefunds() internal {
        // default to 10%
        refundPenaltyBasisPoints = 1000;
    }

    function expireAndRefundFor(address payable _keyOwner, uint256 amount)
        external
    {
        _onlyMembershipManager();
        _hasValidKey(_keyOwner);
        _cancelAndRefund(_keyOwner, amount);
    }

    function cancelAndRefund(uint256 _tokenId) external {
        _onlyKeyManagerOrApproved(_tokenId);
        address payable keyOwner = payable(ownerOf(_tokenId));
        uint256 refund = _getCancelAndRefundValue(keyOwner);

        _cancelAndRefund(keyOwner, refund);
    }

    function updateRefundPenalty(
        uint256 _freeTrialLength,
        uint256 _refundPenaltyBasisPoints
    ) external {
        _onlyMembershipManager();
        emit RefundPenaltyChanged(_freeTrialLength, _refundPenaltyBasisPoints);

        freeTrialLength = _freeTrialLength;
        refundPenaltyBasisPoints = _refundPenaltyBasisPoints;
    }

    function getCancelAndRefundValueFor(address _keyOwner)
        external
        view
        returns (uint256 refund)
    {
        return _getCancelAndRefundValue(_keyOwner);
    }

    function _cancelAndRefund(address payable _keyOwner, uint256 refund)
        internal
    {
        Key memory key = getKeyByOwner(_keyOwner);

        emit CancelKey(key.tokenId, _keyOwner, msg.sender, refund);
        _updateKeyExpirationTimestamp(_keyOwner, block.timestamp);

        if (refund > 0) {
            _transfer(tokenAddress, _keyOwner, refund);
        }

        if (address(onKeyCancelHook) != address(0)) {
            onKeyCancelHook.onKeyCancel(msg.sender, _keyOwner, refund);
        }
    }

    function _getCancelAndRefundValue(address _keyOwner)
        private
        view
        returns (uint256 refund)
    {
        _hasValidKey(_keyOwner);
        Key memory key = getKeyByOwner(_keyOwner);

        if (expirationDuration == type(uint256).max) {
            return keyPrice;
        }

        uint256 timeRemaining = key.expirationTimestamp - block.timestamp;
        if (timeRemaining + freeTrialLength >= expirationDuration) {
            refund = keyPrice;
        } else {
            refund = (keyPrice * timeRemaining) / expirationDuration;
        }

        if (
            freeTrialLength == 0 ||
            timeRemaining + freeTrialLength < expirationDuration
        ) {
            uint256 penalty = (keyPrice * refundPenaltyBasisPoints) /
                BASIS_POINTS_DEN;
            if (refund > penalty) {
                refund -= penalty;
            } else {
                refund = 0;
            }
        }
    }

    uint256[1000] private __safe_upgrade_gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./MembershipDisable.sol";
import "./Keys.sol";
import "./MembershipCore.sol";
import "./Funds.sol";

contract Purchase is Funds, MembershipDisable, MembershipCore, Keys {
    event RenewKeyPurchase(address indexed owner, uint256 newExpiration);

    event GasRefunded(
        address indexed receiver,
        uint256 refundedAmount,
        address tokenAddress
    );

    event FactoryCallFailed(
        address indexed membershipAddress,
        address factoryAddress
    );

    // default to 0
    uint256 private _gasRefundValue;

    function setGasRefundValue(uint256 _refundValue) external {
        _onlyMembershipManager();
        _gasRefundValue = _refundValue;
    }

    function gasRefundValue() external view returns (uint256 _refundValue) {
        return _gasRefundValue;
    }

    function purchase(
        uint256[] memory _values,
        address[] memory _recipients,
        address[] memory _referrers,
        address[] memory _keyManagers,
        bytes calldata _data
    ) external payable {
        _onlyIfAlive();
        require(maxNumberOfKeys > _totalSupply, "MEMBERSHIP_SOLD_OUT");
        require(
            _recipients.length == _referrers.length,
            "INVALID_REFERRERS_LENGTH"
        );
        require(
            _recipients.length == _keyManagers.length,
            "INVALID_KEY_MANAGERS_LENGTH"
        );

        uint256 totalPriceToPay;

        for (uint256 i = 0; i < _recipients.length; i++) {
            // check recipient address
            address _recipient = _recipients[i];
            require(_recipient != address(0), "INVALID_ADDRESS");

            // Assign the key
            Key memory key = getKeyByOwner(_recipient);
            uint256 newTimeStamp;

            if (key.tokenId == 0) {
                if (expirationDuration == type(uint256).max) {
                    newTimeStamp = type(uint256).max;
                } else {
                    newTimeStamp = block.timestamp + expirationDuration;
                }
                _createNewKey(_recipient, _keyManagers[i], newTimeStamp);
            } else if (key.expirationTimestamp > block.timestamp) {
                require(
                    key.expirationTimestamp != type(uint256).max,
                    "NON_EXPIRING_KEY"
                );

                newTimeStamp = key.expirationTimestamp + expirationDuration;
                _updateKeyExpirationTimestamp(_recipient, newTimeStamp);
                emit RenewKeyPurchase(_recipient, newTimeStamp);
            } else {
                if (expirationDuration == type(uint256).max) {
                    newTimeStamp = type(uint256).max;
                } else {
                    newTimeStamp = block.timestamp + expirationDuration;
                }
                _updateKeyExpirationTimestamp(_recipient, newTimeStamp);
                _setKeyManagerOf(key.tokenId, _keyManagers[i]);
                emit RenewKeyPurchase(_recipient, newTimeStamp);
            }

            uint256 inMemoryKeyPrice = _purchasePriceFor(
                _recipient,
                _referrers[i],
                _data
            );
            totalPriceToPay = totalPriceToPay + inMemoryKeyPrice;

            if (tokenAddress != address(0)) {
                require(
                    inMemoryKeyPrice <= _values[i],
                    "INSUFFICIENT_ERC20_VALUE"
                );
            }

            try
                factoryProtocol.recordKeyPurchase{gas: 300000}(
                    inMemoryKeyPrice,
                    _referrers[i]
                )
            {} catch {
                emit FactoryCallFailed(address(this), address(factoryProtocol));
            }

            uint256 pricePaid = tokenAddress == address(0)
                ? msg.value
                : _values[i];
            if (address(onKeyPurchaseHook) != address(0)) {
                onKeyPurchaseHook.onKeyPurchase(
                    msg.sender,
                    _recipient,
                    _referrers[i],
                    _data,
                    inMemoryKeyPrice,
                    pricePaid
                );
            }
        }

        if (tokenAddress != address(0)) {
            IERC20Upgradeable token = IERC20Upgradeable(tokenAddress);
            token.transferFrom(msg.sender, address(this), totalPriceToPay);
        } else {
            require(totalPriceToPay <= msg.value, "INSUFFICIENT_VALUE");
        }

        if (_gasRefundValue != 0) {
            if (tokenAddress != address(0)) {
                IERC20Upgradeable token = IERC20Upgradeable(tokenAddress);
                token.transferFrom(address(this), msg.sender, _gasRefundValue);
            } else {
                (bool success, ) = msg.sender.call{value: _gasRefundValue}("");
                require(success, "REFUND_FAILED");
            }
            emit GasRefunded(msg.sender, _gasRefundValue, tokenAddress);
        }
    }

    function purchasePriceFor(
        address _recipient,
        address _referrer,
        bytes calldata _data
    ) external view returns (uint256 minKeyPrice) {
        minKeyPrice = _purchasePriceFor(_recipient, _referrer, _data);
    }

    function _purchasePriceFor(
        address _recipient,
        address _referrer,
        bytes memory _data
    ) internal view returns (uint256 minKeyPrice) {
        if (address(onKeyPurchaseHook) != address(0)) {
            minKeyPrice = onKeyPurchaseHook.keyPurchasePrice(
                msg.sender,
                _recipient,
                _referrer,
                _data
            );
        } else {
            minKeyPrice = keyPrice;
        }
        return minKeyPrice;
    }

    uint256[1000] private __safe_upgrade_gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol';
import '../FactoryUtils.sol';
import './Keys.sol';
import './MembershipCore.sol';
import './Roles.sol';

contract MembershipMetadata is
  ERC165StorageUpgradeable,
  Roles,
  MembershipCore,
  Keys
{
  using FactoryUtils for uint;
  using FactoryUtils for address;
  using FactoryUtils for string;

  // A descriptive name for a collection of NFTs
  string public name;

  // An abbreviated name for NFTs in this contract. Defaults to "KEY" but is settable by membership owner
  string private membershipSymbol;

  // the base Token URI for this Membership. If not set by membership owner, the global URI stored in Factory is used.
  string private baseTokenURI;

  event NewMembershipSymbol(
    string symbol
  );

  function _initializeMembershipMetadata(
    string calldata _membershipName
  ) internal
  {
    ERC165StorageUpgradeable.__ERC165Storage_init();
    name = _membershipName;
    _registerInterface(0x5b5e139f);
  }

  function updateMembershipName(
    string calldata _membershipName
  ) external
  {
    _onlyMembershipManager();
    name = _membershipName;
  }

  function updateMembershipSymbol(
    string calldata _membershipSymbol
  ) external
  {
    _onlyMembershipManager();
    membershipSymbol = _membershipSymbol;
    emit NewMembershipSymbol(_membershipSymbol);
  }

  function symbol()
    external view
    returns(string memory)
  {
    if(bytes(membershipSymbol).length == 0) {
      return factoryProtocol.globalTokenSymbol();
    } else {
      return membershipSymbol;
    }
  }

  function setBaseTokenURI(
    string calldata _baseTokenURI
  ) external
  {
    _onlyMembershipManager();
    baseTokenURI = _baseTokenURI;
  }

  function tokenURI(
    uint256 _tokenId
  ) external
    view
    returns(string memory)
  {
    string memory URI;
    string memory tokenId;
    string memory membershipAddress = address(this).address2Str();
    string memory seperator;

    if(_tokenId != 0) {
      tokenId = _tokenId.uint2Str();
    } else {
      tokenId = '';
    }

    if(address(onTokenURIHook) != address(0))
    {
      address tokenOwner = ownerOf(_tokenId);
      uint expirationTimestamp = keyExpirationTimestampFor(tokenOwner);

      return onTokenURIHook.tokenURI(
        address(this),
        msg.sender,
        tokenOwner,
        _tokenId,
        expirationTimestamp
        );
    }

    if(bytes(baseTokenURI).length == 0) {
      URI = factoryProtocol.globalBaseTokenURI();
      seperator = '/';
    } else {
      URI = baseTokenURI;
      seperator = '';
      membershipAddress = '';
    }

    return URI.strConcat(
        membershipAddress,
        seperator,
        tokenId
      );
  }

  function supportsInterface(bytes4 interfaceId) 
    public 
    view 
    virtual 
    override(
      AccessControlUpgradeable,
      ERC165StorageUpgradeable
    ) 
    returns (bool) 
    {
    return super.supportsInterface(interfaceId);
  }

  uint256[1000] private __safe_upgrade_gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import './Funds.sol';
import './Roles.sol';

contract MembershipDisable is
  Roles,
  Funds
{
  // Used to disable payable functions when deprecating an old membership
  bool public isAlive;

  event Disable();

  function _initializeDisable(
  ) internal
  {
    isAlive = true;
  }

  // Only allow usage when contract is Alive
  function _onlyIfAlive() 
  internal
  view 
  {
    require(isAlive, 'MEMBERSHIP_DEPRECATED');
  }

  function disableMembership()
    external
  {
    _onlyMembershipManager();
    _onlyIfAlive();
    emit Disable();
    isAlive = false;
  }
  
  uint256[1000] private __safe_upgrade_gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import './MembershipDisable.sol';
import './Roles.sol';
import '../interfaces/IFactory.sol';
import './Funds.sol';
import '../interfaces/hooks/IMembershipKeyCancelHook.sol';
import '../interfaces/hooks/IMembershipKeyPurchaseHook.sol';
import '../interfaces/hooks/IMembershipValidKeyHook.sol';
import '../interfaces/hooks/IMembershipTokenURIHook.sol';

contract MembershipCore is
  Roles,
  Funds,
  MembershipDisable
{
  using AddressUpgradeable for address;

  event Withdrawal(
    address indexed sender,
    address indexed tokenAddress,
    address indexed beneficiary,
    uint amount
  );

  event PricingChanged(
    uint oldKeyPrice,
    uint keyPrice,
    address oldTokenAddress,
    address tokenAddress
  );

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  // Factory Protocol address
  IFactory public factoryProtocol;

  // Duration in seconds for which the keys are valid, after creation
  uint public expirationDuration;

  // price in wei of the next key
  uint public keyPrice;

  // Max number of keys sold if the keyReleaseMechanism is public
  uint public maxNumberOfKeys;

  // A count of how many new key purchases there have been
  uint internal _totalSupply;

  // The account which will receive funds on withdrawal
  address payable public beneficiary;

  // The denominator component for values specified in basis points.
  uint internal constant BASIS_POINTS_DEN = 10000;

  IMembershipKeyPurchaseHook public onKeyPurchaseHook;
  IMembershipKeyCancelHook public onKeyCancelHook;
  IMembershipValidKeyHook public onValidKeyHook;
  IMembershipTokenURIHook public onTokenURIHook;

  function _onlyMembershipManagerOrBeneficiary() 
  internal 
  view
  {
    require(
      isMembershipManager(msg.sender) || msg.sender == beneficiary,
      'ONLY_MEMBERSHIP_MANAGER_OR_BENEFICIARY'
    );
  }
  
  function _initializeMembershipCore(
    address payable _beneficiary,
    uint _expirationDuration,
    uint _keyPrice,
    uint _maxNumberOfKeys
  ) internal
  {
    factoryProtocol = IFactory(msg.sender); // Make sure we link back to Factory's smart contract.
    beneficiary = _beneficiary;
    expirationDuration = _expirationDuration;
    keyPrice = _keyPrice;
    maxNumberOfKeys = _maxNumberOfKeys;
  }

  // The version number of the current implementation on this network
  function publicMembershipVersion(
  ) public pure
    returns (uint16)
  {
    return 10;
  }

  function withdraw(
    address _tokenAddress,
    uint _amount
  ) external
  {
    _onlyMembershipManagerOrBeneficiary();

    // get balance
    uint balance;
    if(_tokenAddress == address(0)) {
      balance = address(this).balance;
    } else {
      balance = IERC20Upgradeable(_tokenAddress).balanceOf(address(this));
    }

    uint amount;
    if(_amount == 0 || _amount > balance)
    {
      require(balance > 0, 'NOT_ENOUGH_FUNDS');
      amount = balance;
    }
    else
    {
      amount = _amount;
    }

    emit Withdrawal(msg.sender, _tokenAddress, beneficiary, amount);
    _transfer(_tokenAddress, beneficiary, amount);
  }

  function updateKeyPricing(
    uint _keyPrice,
    address _tokenAddress
  )
    external
  {
    _onlyIfAlive();
    _onlyMembershipManager();
    _isValidToken(_tokenAddress);
    uint oldKeyPrice = keyPrice;
    address oldTokenAddress = tokenAddress;
    keyPrice = _keyPrice;
    tokenAddress = _tokenAddress;
    emit PricingChanged(oldKeyPrice, keyPrice, oldTokenAddress, tokenAddress);
  }

  function updateBeneficiary(
    address payable _beneficiary
  ) external {
    _onlyMembershipManagerOrBeneficiary();
    require(_beneficiary != address(0), 'INVALID_ADDRESS');
    beneficiary = _beneficiary;
  }

  function setEventHooks(
    address _onKeyPurchaseHook,
    address _onKeyCancelHook,
    address _onValidKeyHook,
    address _onTokenURIHook
  ) external
  {
    _onlyMembershipManager();
    require(_onKeyPurchaseHook == address(0) || _onKeyPurchaseHook.isContract(), 'INVALID_ON_KEY_SOLD_HOOK');
    require(_onKeyCancelHook == address(0) || _onKeyCancelHook.isContract(), 'INVALID_ON_KEY_CANCEL_HOOK');
    require(_onValidKeyHook == address(0) || _onValidKeyHook.isContract(), 'INVALID_ON_VALID_KEY_HOOK');
    require(_onTokenURIHook == address(0) || _onTokenURIHook.isContract(), 'INVALID_ON_TOKEN_URI_HOOK');
    onKeyPurchaseHook = IMembershipKeyPurchaseHook(_onKeyPurchaseHook);
    onKeyCancelHook = IMembershipKeyCancelHook(_onKeyCancelHook);
    onTokenURIHook = IMembershipTokenURIHook(_onTokenURIHook);
    onValidKeyHook = IMembershipValidKeyHook(_onValidKeyHook);
  }

  function totalSupply()
    public
    view returns(uint256)
  {
    return _totalSupply;
  }

  function approveBeneficiary(
    address _spender,
    uint _amount
  ) public
    returns (bool)
  {
    _onlyMembershipManagerOrBeneficiary();
    return IERC20Upgradeable(tokenAddress).approve(_spender, _amount);
  }

  uint256[1000] private __safe_upgrade_gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./MembershipCore.sol";

contract Keys is MembershipCore {
    // The struct for a key
    struct Key {
        uint256 tokenId;
        uint256 expirationTimestamp;
    }

    // Emitted when the Membership owner expires a user's Key
    event ExpireKey(uint256 indexed tokenId);

    // Emitted when the expiration of a key is modified
    event ExpirationChanged(
        uint256 indexed _tokenId,
        uint256 _amount,
        bool _timeAdded
    );

    event KeyManagerChanged(
        uint256 indexed _tokenId,
        address indexed _newManager
    );

    mapping(address => Key) internal keyByOwner;

    mapping(uint256 => address) internal _ownerOf;

    uint256 public numberOfOwners;

    mapping(uint256 => address) public keyManagerOf;

    mapping(uint256 => address) private approved;

    mapping(address => mapping(address => bool))
        private managerToOperatorApproved;

    function _onlyKeyManagerOrApproved(uint256 _tokenId) internal view {
        require(
            _isKeyManager(_tokenId, msg.sender) ||
                _isApproved(_tokenId, msg.sender) ||
                isApprovedForAll(_ownerOf[_tokenId], msg.sender),
            "ONLY_KEY_MANAGER_OR_APPROVED"
        );
    }

    function _hasValidKey(address _user) internal view {
        require(getHasValidKey(_user), "KEY_NOT_VALID");
    }

    function _isKey(uint256 _tokenId) internal view {
        require(_ownerOf[_tokenId] != address(0), "NO_SUCH_KEY");
    }

    function getKeyByOwner(address _keyOwner)
        internal
        view
        returns (Key memory)
    {
        return keyByOwner[_keyOwner];
    }

    function _createNewKey(
        address _recipient,
        address _keyManager,
        uint256 expirationTimestamp
    ) internal returns (uint256) {
        Key storage key = keyByOwner[_recipient];

        // We increment the tokenId counter
        _totalSupply++;
        key.tokenId = _totalSupply;

        // This is a brand new owner
        _recordOwner(_recipient, key.tokenId);

        // set expiration
        key.expirationTimestamp = expirationTimestamp;

        // set key manager
        _setKeyManagerOf(key.tokenId, _keyManager);

        emit Transfer(
            address(0), // This is a creation.
            _recipient,
            key.tokenId
        );

        return key.tokenId;
    }

    function _transferKey(
        uint256 _tokenId,
        address _recipient,
        uint256 expirationTimestamp
    ) internal returns (uint256) {
        Key storage key = keyByOwner[_recipient];
        require(key.tokenId == 0, "OWNER_ALREADY_HAS_KEY");

        // set new key
        key.tokenId = _tokenId;

        // store ownership
        _recordOwner(_recipient, _tokenId);

        // set expiration
        key.expirationTimestamp = expirationTimestamp;

        return key.tokenId;
    }

    function _updateKeyExpirationTimestamp(
        address _keyOwner,
        uint256 newExpirationTimestamp
    ) internal {
        keyByOwner[_keyOwner].expirationTimestamp = newExpirationTimestamp;
    }

    function _updateKeyTokenId(address _keyOwner, uint256 _tokenId) internal {
        keyByOwner[_keyOwner].tokenId = _tokenId;
    }

    function _expireKey(address _keyOwner) internal {
        // Effectively expiring the key
        keyByOwner[_keyOwner].expirationTimestamp = block.timestamp;
        // Set the tokenID to 0 to avoid duplicates
        keyByOwner[_keyOwner].tokenId = 0;
    }

    function balanceOf(address _keyOwner) public view returns (uint256) {
        require(_keyOwner != address(0), "INVALID_ADDRESS");
        return getHasValidKey(_keyOwner) ? 1 : 0;
    }

    function getHasValidKey(address _keyOwner)
        public
        view
        returns (bool isValid)
    {
        isValid =
            getKeyByOwner(_keyOwner).expirationTimestamp > block.timestamp;

        // use hook if it exists
        if (address(onValidKeyHook) != address(0)) {
            isValid = onValidKeyHook.hasValidKey(
                address(this),
                _keyOwner,
                getKeyByOwner(_keyOwner).expirationTimestamp,
                isValid
            );
        }
    }

    function getTokenIdFor(address _account) public view returns (uint256) {
        return getKeyByOwner(_account).tokenId;
    }

    function keyExpirationTimestampFor(address _keyOwner)
        public
        view
        returns (uint256)
    {
        return getKeyByOwner(_keyOwner).expirationTimestamp;
    }

    // Returns the owner of a given tokenId
    function ownerOf(uint256 _tokenId) public view returns (address) {
        return _ownerOf[_tokenId];
    }

    function setKeyManagerOf(uint256 _tokenId, address _keyManager) public {
        _isKey(_tokenId);
        require(
            _isKeyManager(_tokenId, msg.sender) ||
                isMembershipManager(msg.sender),
            "UNAUTHORIZED_KEY_MANAGER_UPDATE"
        );
        _setKeyManagerOf(_tokenId, _keyManager);
    }

    function _setKeyManagerOf(uint256 _tokenId, address _keyManager) internal {
        if (keyManagerOf[_tokenId] != _keyManager) {
            keyManagerOf[_tokenId] = _keyManager;
            _clearApproval(_tokenId);
            emit KeyManagerChanged(_tokenId, _keyManager);
        }
    }

    function approve(address _approved, uint256 _tokenId) public {
        _onlyKeyManagerOrApproved(_tokenId);
        _onlyIfAlive();
        require(msg.sender != _approved, "APPROVE_SELF");

        approved[_tokenId] = _approved;
        emit Approval(_ownerOf[_tokenId], _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        _isKey(_tokenId);
        address approvedRecipient = approved[_tokenId];
        return approvedRecipient;
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        uint256 tokenId = getKeyByOwner(_owner).tokenId;
        address keyManager = keyManagerOf[tokenId];
        if (keyManager == address(0)) {
            return managerToOperatorApproved[_owner][_operator];
        } else {
            return managerToOperatorApproved[keyManager][_operator];
        }
    }

    function _isKeyManager(uint256 _tokenId, address _keyManager)
        internal
        view
        returns (bool)
    {
        if (
            keyManagerOf[_tokenId] == _keyManager ||
            (keyManagerOf[_tokenId] == address(0) &&
                ownerOf(_tokenId) == _keyManager)
        ) {
            return true;
        } else {
            return false;
        }
    }

    function _recordOwner(address _keyOwner, uint256 _tokenId) internal {
        // check expiration ts should be set to know if owner had previously registered a key
        Key memory key = getKeyByOwner(_keyOwner);
        if (key.expirationTimestamp == 0) {
            numberOfOwners++;
        }

        // We register the owner of the tokenID
        _ownerOf[_tokenId] = _keyOwner;
    }

    function _timeMachine(
        uint256 _tokenId,
        uint256 _deltaT,
        bool _addTime
    ) internal {
        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner != address(0), "NON_EXISTENT_KEY");
        Key storage key = keyByOwner[tokenOwner];
        uint256 formerTimestamp = key.expirationTimestamp;
        bool validKey = getHasValidKey(tokenOwner);
        if (_addTime) {
            if (validKey) {
                key.expirationTimestamp = formerTimestamp + _deltaT;
            } else {
                key.expirationTimestamp = block.timestamp + _deltaT;
            }
        } else {
            key.expirationTimestamp = formerTimestamp - _deltaT;
        }
        emit ExpirationChanged(_tokenId, _deltaT, _addTime);
    }

    function setApprovalForAll(address _to, bool _approved) public {
        _onlyIfAlive();
        require(_to != msg.sender, "APPROVE_SELF");
        managerToOperatorApproved[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }

    function _isApproved(uint256 _tokenId, address _user)
        internal
        view
        returns (bool)
    {
        return approved[_tokenId] == _user;
    }

    function _clearApproval(uint256 _tokenId) internal {
        if (approved[_tokenId] != address(0)) {
            approved[_tokenId] = address(0);
        }
    }

    function setMaxNumberOfKeys(uint256 _maxNumberOfKeys) external {
        _onlyMembershipManager();
        require(
            _maxNumberOfKeys >= _totalSupply,
            "MAX_NUMBER_KEYS_IS_SMALLER_THAN_CURRENT_SUPPLY"
        );
        maxNumberOfKeys = _maxNumberOfKeys;
    }

    function setExpirationDuration(uint256 _newExpirationDuration) external {
        _onlyMembershipManager();
        expirationDuration = _newExpirationDuration;
    }

    uint256[1000] private __safe_upgrade_gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import './Keys.sol';
import './Roles.sol';

contract GrantKeys is
  Roles,
  Keys
{
  function grantKeys(
    address[] calldata _recipients,
    uint[] calldata _expirationTimestamps,
    address[] calldata _keyManagers
  ) external {
    require(isKeyGranter(msg.sender) || isMembershipManager(msg.sender), 'ONLY_MEMBERSHIP_MANAGER_OR_KEY_GRANTER');

    for(uint i = 0; i < _recipients.length; i++) {
      address recipient = _recipients[i];
      uint expirationTimestamp = _expirationTimestamps[i];
      address keyManager = _keyManagers[i];

      require(recipient != address(0), 'INVALID_ADDRESS');

      Key memory toKey = getKeyByOwner(recipient);
      require(expirationTimestamp > toKey.expirationTimestamp, 'ALREADY_OWNS_KEY');

      if(toKey.tokenId == 0) {
        _createNewKey(
          recipient,
          keyManager,
          expirationTimestamp
        );
      } else {
        _setKeyManagerOf(toKey.tokenId, keyManager);
        emit KeyManagerChanged(toKey.tokenId, keyManager);

        _updateKeyExpirationTimestamp(
          recipient,
          expirationTimestamp
        );
      
        emit Transfer(
          address(0), // This is a creation.
          recipient,
          toKey.tokenId
        );
      }
      
    }
  }

  uint256[1000] private __safe_upgrade_gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract Funds {
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public tokenAddress;

    function _initializeFunds(address _tokenAddress) internal {
        _isValidToken(_tokenAddress);
        tokenAddress = _tokenAddress;
    }

    function _isValidToken(address _tokenAddress) internal view {
        require(
            _tokenAddress == address(0) ||
                IERC20Upgradeable(_tokenAddress).totalSupply() > 0,
            "INVALID_TOKEN"
        );
    }

    function _transfer(
        address _tokenAddress,
        address payable _to,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            if (_tokenAddress == address(0)) {
                _to.sendValue(_amount);
            } else {
                IERC20Upgradeable token = IERC20Upgradeable(_tokenAddress);
                token.safeTransfer(_to, _amount);
            }
        }
    }

    uint256[1000] private __safe_upgrade_gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Keys.sol";
import "./MembershipCore.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";

contract ERC721Enumerable is
    ERC165StorageUpgradeable,
    MembershipCore, // Implements totalSupply
    Keys
{
    function _initializeERC721Enumerable() internal {
        _registerInterface(0x780e9d63);
    }

    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require(_index < _totalSupply, "OUT_OF_RANGE");
        return _index;
    }

    function tokenOfOwnerByIndex(address _keyOwner, uint256 _index)
        public
        view
        returns (uint256)
    {
        require(
            _index < balanceOf(_keyOwner) && _keyOwner != address(0),
            "ONLY_ONE_KEY_PER_OWNER"
        );
        return getTokenIdFor(_keyOwner);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC165StorageUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    uint256[1000] private __safe_upgrade_gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./MembershipCore.sol";

contract ConvenienceOwnable is MembershipCore {
    address private _convenienceOwner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    function _initializeConvenienceOwnable(address _sender) internal {
        _convenienceOwner = _sender;
    }

    function owner() public view returns (address) {
        return _convenienceOwner;
    }

    function setOwner(address account) public {
        _onlyMembershipManager();
        require(account != address(0), "OWNER_CANT_BE_ADDRESS_ZERO");
        address _previousOwner = _convenienceOwner;
        _convenienceOwner = account;
        emit OwnershipTransferred(_previousOwner, account);
    }

    function isOwner(address account) public view returns (bool) {
        return _convenienceOwner == account;
    }

    uint256[1000] private __safe_upgrade_gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

interface IMembershipValidKeyHook {
    function hasValidKey(
        address membershipAddress,
        address keyOwner,
        uint256 expirationTimestamp,
        bool isValidKey
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

interface IMembershipTokenURIHook {
    function tokenURI(
        address membershipAddress,
        address operator,
        address owner,
        uint256 keyId,
        uint256 expirationTimestamp
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

interface IMembershipKeyPurchaseHook {
    function keyPurchasePrice(
        address from,
        address recipient,
        address referrer,
        bytes calldata data
    ) external view returns (uint256 minKeyPrice);

    function onKeyPurchase(
        address from,
        address recipient,
        address referrer,
        bytes calldata data,
        uint256 minKeyPrice,
        uint256 pricePaid
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

interface IMembershipKeyCancelHook {
    function onKeyCancel(
        address operator,
        address to,
        uint256 refund
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

interface IFactory {
    function initialize(address _factoryOwner) external;

    function initializeProxyAdmin() external;

    function proxyAdminAddress() external view;

    function createMembership(
        uint256 _expirationDuration,
        address _tokenAddress,
        uint256 _keyPrice,
        uint256 _maxNumberOfKeys,
        string calldata _membershipName,
        bytes12 // _salt
    ) external returns (address);

    function createUpgradeableMembership(bytes memory data)
        external
        returns (address);

    function createUpgradeableMembershipAtVersion(
        bytes memory data,
        uint16 _membershipVersion
    ) external returns (address);

    function upgradeMembership(
        address payable membershipAddress,
        uint16 version
    ) external returns (address);

    function recordKeyPurchase(uint256 _value, address _referrer) external;

    function globalBaseTokenURI() external view returns (string memory);

    function globalTokenSymbol() external view returns (string memory);

    function chainId() external view returns (uint256);

    function configFactory(
        address _udt,
        address _weth,
        uint256 _estimatedGasForPurchase,
        string calldata _symbol,
        string calldata _URI,
        uint256 _chainId
    ) external;

    function addMembershipTemplate(address impl, uint16 version) external;

    function publicMembershipImpls(uint16 _version) external view;

    function publicMembershipVersions(address _impl) external view;

    function publicMembershipLatestVersion() external view;

    function setMembershipTemplate(address payable _publicMembershipAddress)
        external;

    function resetTrackedValue(
        uint256 _grossNetworkProduct,
        uint256 _totalDiscountGranted
    ) external;

    function grossNetworkProduct() external view returns (uint256);

    function totalDiscountGranted() external view returns (uint256);

    function memberships(address)
        external
        view
        returns (
            bool deployed,
            uint256 totalSales,
            uint256 yieldedDiscountTokens
        );

    function publicMembershipAddress() external view returns (address);

    function uniswapOracles(address) external view returns (address);

    function weth() external view returns (address);

    function udt() external view returns (address);

    function estimatedGasForPurchase() external view returns (uint256);

    function networkBaseFee() external view returns (uint256);

    function factoryVersion() external pure returns (uint16);

    function setOracle(address _tokenAddress, address _oracleAddress) external;

    function __initializeOwnable(address sender) external;

    function isOwner() external view returns (bool);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

interface IDemoverseMembership {
    /// Functions
    function initialize(
        address _membershipCreator,
        uint256 _expirationDuration, // if === 0 non-expiring membership
        address _tokenAddress,
        uint256 _keyPrice, // membership price
        uint256 _maxNumberOfKeys, // NFTs max count
        string calldata _membershipName, // membership name,
        uint256 _royaltyPercent // royalty percentage
    ) external;

    // roles
    function DEFAULT_ADMIN_ROLE() external pure returns (bytes32);

    function KEY_GRANTER_ROLE() external pure returns (bytes32);

    function MEMBERSHIP_MANAGER_ROLE() external pure returns (bytes32);

    function publicMembershipVersion() external pure returns (uint16);

    function disableMembership() external;

    function withdraw(address _tokenAddress, uint256 _amount) external;

    function approveBeneficiary(address _spender, uint256 _amount)
        external
        returns (bool);

    function updateKeyPricing(uint256 _keyPrice, address _tokenAddress)
        external;

    function setExpirationDuration(uint256 _newExpirationDuration) external;

    function updateBeneficiary(address _beneficiary) external;

    function getHasValidKey(address _user) external view returns (bool);

    function getTokenIdFor(address _account) external view returns (uint256);

    function keyExpirationTimestampFor(address _keyOwner)
        external
        view
        returns (uint256 timestamp);

    function numberOfOwners() external view returns (uint256);

    function updateMembershipName(string calldata _membershipName) external;

    function updateMembershipSymbol(string calldata _membershipSymbol) external;

    function symbol() external view returns (string memory);

    function setBaseTokenURI(string calldata _baseTokenURI) external;

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function setEventHooks(
        address _onKeyPurchaseHook,
        address _onKeyCancelHook,
        address _onValidKeyHook,
        address _onTokenURIHook
    ) external;

    function grantKeys(
        address[] calldata _recipients,
        uint256[] calldata _expirationTimestamps,
        address[] calldata _keyManagers
    ) external;

    function purchase(
        uint256 _value,
        address _recipient,
        address _referrer,
        address _keyManager,
        bytes calldata _data
    ) external payable;

    function setGasRefundValue(uint256 _gasRefundValue) external;

    function gasRefundValue() external view returns (uint256 _gasRefundValue);

    function purchasePriceFor(
        address _recipient,
        address _referrer,
        bytes calldata _data
    ) external view returns (uint256);

    function updateTransferFee(uint256 _transferFeeBasisPoints) external;

    function getTransferFee(address _keyOwner, uint256 _time)
        external
        view
        returns (uint256);

    function expireAndRefundFor(address _keyOwner, uint256 amount) external;

    function cancelAndRefund(uint256 _tokenId) external;

    function updateRefundPenalty(
        uint256 _freeTrialLength,
        uint256 _refundPenaltyBasisPoints
    ) external;

    function getCancelAndRefundValueFor(address _keyOwner)
        external
        view
        returns (uint256 refund);

    function addKeyGranter(address account) external;

    function addMembershipManager(address account) external;

    function isKeyGranter(address account) external view returns (bool);

    function isMembershipManager(address account) external view returns (bool);

    function onKeyPurchaseHook() external view returns (address);

    function onKeyCancelHook() external view returns (address);

    function onValidKeyHook() external view returns (bool);

    function onTokenURIHook() external view returns (string memory);

    function revokeKeyGranter(address _granter) external;

    function renounceMembershipManager() external;

    // *** ///
    function beneficiary() external view returns (address);

    function expirationDuration() external view returns (uint256);

    function freeTrialLength() external view returns (uint256);

    function isAlive() external view returns (bool);

    function keyPrice() external view returns (uint256);

    function maxNumberOfKeys() external view returns (uint256);

    function refundPenaltyBasisPoints() external view returns (uint256);

    function tokenAddress() external view returns (address);

    function transferFeeBasisPoints() external view returns (uint256);

    function factoryProtocol() external view returns (address);

    function keyManagerOf(uint256) external view returns (address);

    /// *** ///

    function shareKey(
        address _to,
        uint256 _tokenId,
        uint256 _timeShared
    ) external;

    function setKeyManagerOf(uint256 _tokenId, address _keyManager) external;

    function name() external view returns (string memory _name);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address _owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 _tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address _owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address _owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function owner() external view returns (address);

    function setOwner(address account) external;

    function isOwner(address account) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <=0.9.0;

library FactoryUtils {

  function strConcat(
    string memory _a,
    string memory _b,
    string memory _c,
    string memory _d
  ) internal pure
    returns (string memory _concatenatedString)
  {
    return string(abi.encodePacked(_a, _b, _c, _d));
  }

  function uint2Str(
    uint _i
  ) internal pure
    returns (string memory _uintAsString)
  {
    // make a copy of the param to avoid security/no-assign-params error
    uint c = _i;
    if (_i == 0) {
      return '0';
    }
    uint j = _i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (c != 0) {
        k = k-1;
        uint8 temp = (48 + uint8(c - c / 10 * 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        c /= 10;
    }
    return string(bstr);
  }

  function address2Str(
    address _addr
  ) internal pure
    returns(string memory)
  {
    bytes32 value = bytes32(uint256(uint160(_addr)));
    bytes memory alphabet = '0123456789abcdef';
    bytes memory str = new bytes(42);
    str[0] = '0';
    str[1] = 'x';
    for (uint i = 0; i < 20; i++) {
      str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
      str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
    }
    return string(str);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165StorageUpgradeable is Initializable, ERC165Upgradeable {
    function __ERC165Storage_init() internal onlyInitializing {
        __ERC165_init_unchained();
        __ERC165Storage_init_unchained();
    }

    function __ERC165Storage_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}