// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";


contract SAFTContract is Ownable {

    uint256 public constant referralReward = 4;
    uint256 public constant founderReward = 20;

    uint256 public constant k = 34500000;
    uint256 public constant k2 = 124;
    uint256 public constant initialPriceUSD = 100000000000000000;
    uint256 public constant exponent = (10 ** 18) * (10 ** 4) * (10**18);

    uint256 public reservedSupply;

    struct SAFTData {
        uint128 usdCost;
        uint128 tokenAmount;
        bool redeemed;
        bytes32 affCode;
    }

    uint256 public numberOfPartners;
    address[] public SAFTAddresses;
    mapping(address => SAFTData) public addressSAFTData;

    event AddedSAFTPartner(
        address partnerAddress,
        uint256 usdCost,
        uint256 tokenAmount,
        bytes32 affCode,
        string name
    );
    event RedeemerChanged(address owner, address redeemer);
    event RemovedAll(address[] _removedAddresses);

    address public redeemer;

    /**
     * @dev Throws if sender is not redeemer
     */
    modifier onlyRedeemer() {
        require(redeemer == msg.sender, "Sender is not redeemer");
        _;
    }

    /**
     * @notice Calculate how much saft contractor have to pay for given amount of xla tokens
     * @param _amount amount of tokens user wants to buy
     * @return cost usd price for given amount of tokens
     */
    function calculateCost(uint256 _amount) public view returns (uint256 cost) {
        cost = (k2 * _amount * (
            reservedSupply * k + initialPriceUSD * (10**18)
        ) * (10**2) + (k2 ** 2) * (_amount ** 2) * (k / 2)) / exponent;
    }

    /**
     * @notice register SAFT partner
     * @param _partner address of partner who bought tokens through SAFT
     * @param _tokens amount of tokens user wants to buy
     * @param _affCode Affiliate code that was used in purchase
     * @param _name  Name of the SAFT partners
     */
    function addSAFTPartner(
        address _partner,
        uint256 _tokens,
        bytes32 _affCode,
        string calldata _name
    ) public onlyOwner {
        require(addressSAFTData[_partner].tokenAmount == 0, "SAFT Partner already registered");
        uint256 cost = calculateCost(_tokens);

        uint256 affiliateAmount;
        if (_affCode != "") {
            affiliateAmount = _tokens / 100 * referralReward;
        }

        uint256 founderAmount = _tokens / 100 * founderReward;
        uint256 allTokens = _tokens + affiliateAmount + founderAmount;
        reservedSupply += allTokens;

        SAFTAddresses.push(_partner);
        numberOfPartners += 1;
        addressSAFTData[_partner] = SAFTData(uint128(cost), uint128(_tokens), false, _affCode);

        emit AddedSAFTPartner(_partner, cost, _tokens, _affCode, _name);
    }

    /**
     * @notice Remove all current SAFT Partners and set new SAFT partners from based on given args
     * @param _partners List of addresses of partners who bought tokens through SAFT
     * @param _tokens List of tokens amount which user want to buy
     * @param _affCodes List Affiliate codes that were used in purchase
     * @param _names  List of names for SAFT partners
     */
    function setSAFTPartners(
        address[] calldata _partners,
        uint256[] calldata _tokens,
        bytes32[] calldata _affCodes,
        string[] calldata _names
    ) public onlyOwner {
        removeAll();

        uint256 partnersCount = _partners.length;

        require(
            partnersCount == _tokens.length &&
            partnersCount == _names.length &&
            partnersCount == _affCodes.length,
            "Inconsistent data length"
        );

        for (uint256 i = 0; i < partnersCount;) {
            addSAFTPartner(_partners[i], _tokens[i], _affCodes[i], _names[i]);
            unchecked{i++;}
        }
    }

    /**
     * @notice removes all the SAFT partners
     */
    function removeAll() public onlyOwner {
        uint256 partnersLength = SAFTAddresses.length;
        emit RemovedAll(SAFTAddresses);

        for (uint256 i = 0; i < partnersLength;) {
            address partner = SAFTAddresses[i];
            delete addressSAFTData[partner];
            unchecked{i++;}
        }

       reservedSupply = 0;
       numberOfPartners = 0;
       delete SAFTAddresses;
    }

    /**
     * @notice Allows to change redeemer
     */
    function setRedeemer(address _redeemer) public onlyOwner {
        require(
            _redeemer != redeemer,
            "redeemer already configured"
        );

        redeemer = _redeemer;
        emit RedeemerChanged(msg.sender, _redeemer);
    }

    /**
     * @notice Mark SAFT partner as fulfilled (received promised tokens)
     * @param _partner partner address who was fulfilled
     */
    function markAsRedeemed(address _partner) public onlyRedeemer {
        SAFTData storage partnerData = addressSAFTData[_partner];
        require(partnerData.tokenAmount != 0, "SAFT partner does not exist");
        require(partnerData.redeemed == false, "SAFT partner already redeemed");
        partnerData.redeemed = true;
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