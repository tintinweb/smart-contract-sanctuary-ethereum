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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IGreeting.sol";
import "./interfaces/ICampaign.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract TheGreeting is 
    IGreeting,
    Ownable
{
    
    // List of Campaigns
    ICampaign[] campaigns;
    mapping(ICampaign => bool) isCampaignRegistered;

    // To check whether the address is verified as `having humanity`
    mapping(address => bool) verifiedHumanity;

    // For PUSH Protocol Integration
    address public pushCommContractAddress  = 0xb3971BCef2D791bc4027BbfedFb47319A4AAaaAa;
    address public theGreetingChannelOnPush = address(0);

    // The user can get a list of available campaigns.
    function getCampaignList() external view override returns (ICampaign[] memory) {
        return campaigns;
    }

    // The user can get a list of <CampaignAddress, CampaignName> for available campaigns.
    function getCampaignListAndName() external view override returns (ICampaign[] memory, string[] memory) {
        uint numCampaigns = campaigns.length;
        ICampaign[] memory _campaigns = new ICampaign[](numCampaigns);
        string[] memory _name = new string[](numCampaigns);

        for (uint i = 0; i < numCampaigns; i++) {
            _campaigns[i] = campaigns[i];
            _name[i] = campaigns[i].name();
        }

        return (_campaigns, _name);
    }

    // The user can get a list of available words for a campaign.
    function getGreetingWordList(
        ICampaign campaign
    ) external view override returns (string[] memory) {
        return campaign.getGreetingWordList();
    }

    // The user can select the word for a campaign.
    function selectGreetingWord(
        ICampaign campaign,
        uint wordIndex
    ) external override {
        campaign.selectGreetingWord(msg.sender, wordIndex);
    }

    // The user can get a selected word
    function getSelectedGreetingWord(
        ICampaign campaign,
        address sender
    ) external view override returns (uint, string memory) {
        return campaign.getSelectedGreetingWord(sender);
    }
    
    // The user can get price in Wei per message for a campaign
    function getPricePerMessageInWei(
        ICampaign campaign
    ) external view override returns (uint price) {
        return campaign.getPricePerMessageInWei();
    }

    // The user can send the greeting message to a recipient(to).
    // Make sure that the sender can only one message to a recipient.
    function send(
        ICampaign campaign,
        address to,
        string memory messageURI
    ) external payable override {
        // Determine the price for sending message.
        // If the humanity is verified, the user can send a message for free.
        uint pricePerMessage  = campaign.getPricePerMessageInWei();
        if(verifiedHumanity[msg.sender]) {
            pricePerMessage = 0;
        }

        // Check whether sufficient value is sent to the contract.
        // Return the change to sender if any.
        require(msg.value >= pricePerMessage, "Err: Insufficient msg.value to send message.");
        uint change = msg.value - pricePerMessage;
        payable(msg.sender).transfer(change);

        // Send a Message via Campaign.
        campaign.send(msg.sender, to, messageURI);

        // TODO: Delete Unused Lines
        // Send Notification Via PushProtocol.
        // _sendNotificationViaPush(to,
        //                         campaign.name(), 
        //                         "New greeting coming!"
        //                         );
        
        emit SendMessage(msg.sender, to, address(campaign));
    }

    // The user can get message IDs of Campaign
    function getMessageIdsOfCampaign(
        ICampaign campaign,
        address who,
        ICampaign.MessageType messageType
    ) external view override returns (uint[] memory) {
        return campaign.getMessageIds(who, messageType);
    }

    // The user can get message by ID
    function getMessageByIdOfCampaign(
        ICampaign campaign,
        uint id
    ) external view override returns (ICampaign.MessageResponseDto memory) {
        return campaign.getMessageById(id);
    }

    // The user can register new campaign
    function registerCampaign(
        ICampaign campaign_
    ) external override {
        require(
            ICampaign(campaign_).supportsInterface(type(ICampaign).interfaceId),
            "Err: The given address does not comply with ICampaign."
        );

        require(!isCampaignRegistered[campaign_], "Err: The given campaign is alreaady registered.");
        isCampaignRegistered[campaign_] = true;

        campaigns.push(ICampaign(campaign_));
    }

    // Withdraw Ether
    function withdrawEther(
        address payable destination
    ) external onlyOwner {
        // Send all balaces of the contract to the destination
        destination.transfer(address(this).balance);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

interface ICampaign is
    IERC165
{
    // Message Status
    //  - WAITING_FOR_REPLY: Sender sent a message, but a recipient does not reply.
    //  - REPLIED: Sender and Recipient sent a message each other.
    enum MessageStatus {
        WAITING_FOR_REPLY,
        REPLIED
    }
    
    // Message Type
    //  - INCOMING: Message was sent TO the address (The address was recipient)
    //  - SENT: Message was sent FROM the address (The address was sender)
    enum MessageType {
        INCOMING,
        SENT
    }

    // Struct of Message
    // struct Message {
    //     address sender;
    //     address recipient;
    //     uint greetingWordIndex;
    //     string bodyURI;
    // }

    // Data Transfer Object for Querying message
    struct MessageResponseDto {
        uint id;
        address sender;
        address recipient;
        string greetingWord;
        string bodyURI;
        MessageStatus status;
        bool isResonanced;
    }

    function name() external view returns (string memory);

    /**
     * @dev Get List of Greeting Words
     */
    function getGreetingWordList() external view returns (string[] memory);

    /**
     * @dev Select the greeting Word for a caller.
     */
    function selectGreetingWord(address sender, uint wordIndex) external;
    
    /**
     * @dev Get List of Greeting Words for a certain sender.
     */
    function getSelectedGreetingWord(address sender) external view returns (uint, string memory);

    /**
     * @dev Get a price to send a message in Wei
     */
    function getPricePerMessageInWei() external view returns (uint price);

    /**
     * @dev Get a price to send a message in Wei
     */
    // TODO: This function should be able to be called by only GreetingContract. (As of now, anyone can call the function directly, then bypass the payment.)
    function send(
        address from,
        address to,
        string memory messageURI
    ) external;

    /**
     * @dev Get message IDs for given address and messageType
     */
    function getMessageIds(
        address who,
        MessageType messageType
    ) external view returns (uint[] memory);

    /**
     * @dev Get Message By ID. Construct MessageResponse DTO.
     */
    function getMessageById(
        uint id
    ) external view returns (MessageResponseDto memory);

    /** 
     * @dev Callback function when the Campaign is registered on Greeting Contract.
     *      Now it's not in use.
     */
    function onRegistered() external pure returns (string memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ICampaign.sol";

interface IGreeting {
    // Event emitted when the message is successfully sent
    event SendMessage(address indexed from, address indexed to, address campaign);

    // The user can get a list of available campaigns.
    function getCampaignList() external view returns (ICampaign[] memory);

    // The user can get a list of <CampaignAddress, CampaignName> for available campaigns.
    function getCampaignListAndName() external view returns (ICampaign[] memory, string[] memory);

    // The user can get a list of available words for a campaign.
    function getGreetingWordList(
        ICampaign campaign
    ) external view returns (string[] memory);

    // The user can select the word for a campaign.
    function selectGreetingWord(
        ICampaign campaign,
        uint wordIndex
    ) external;

    // The user can get a selected word
    function getSelectedGreetingWord(
        ICampaign campaign,
        address sender
    ) external view returns (uint, string memory);


    // The user can get price in Wei per message for a campaign
    function getPricePerMessageInWei(
        ICampaign campaign
    ) external view returns (uint price);

    // The user can send the greeting message to a recipient(to).
    // Make sure that the sender can only one message to a recipient.
    function send(
        ICampaign campaign,
        address to,
        string memory messageURI
    ) external payable;

    // The user can get message IDs of Campaign
    function getMessageIdsOfCampaign(
        ICampaign campaign,
        address who,
        ICampaign.MessageType action
    ) external view returns (uint[] memory);

    // The user can get message by ID
    function getMessageByIdOfCampaign(
        ICampaign campaign,
        uint id
    ) external view returns (ICampaign.MessageResponseDto memory);

    // The user can register new campaign
    function registerCampaign(
        ICampaign campaign
    ) external;

    // Withdraw all Ether within the contract to the destination address.
    function withdrawEther(
        address payable destination
    ) external;
}