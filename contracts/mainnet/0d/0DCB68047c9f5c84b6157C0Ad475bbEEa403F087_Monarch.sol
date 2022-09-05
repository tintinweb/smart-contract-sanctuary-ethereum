/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

enum VoteType
{
    NoVote,
    Positive,
    Negative
}
struct Story
{
    address creator;
    string title;
    string message;
    string image;
    uint timestamp;

    int votes;
    uint previousStory;
    uint nextStory;
}

contract Monarch is Ownable {
    // Main data
    mapping(uint => Story) public stories;
    mapping(uint => mapping(address => VoteType)) public userVotes;
    
    // Aux data
    mapping(uint => bool) public isStoryDeleted;
    mapping(address => uint) public userStoriesCount;
    mapping(address => mapping(uint => uint)) public userStories;
    
    uint public STORIES_HEAD;
    uint public NEW_STORY_GOES_AROUND_HERE;
    uint public STORY_ID_MANAGER = 1;

    bool public IS_ACTIVE = false;
    bool public DELETE_STORIES_ALLOWED = false;
    bool public GAS_SAVER_ALLOWED = false;

    // Internal functions

    function getVoteDelta(uint storyId, VoteType voteType) internal returns(int voteDelta)
    {
        require(userVotes[storyId][msg.sender] != voteType, "You already submitted the same vote");

        if(userVotes[storyId][msg.sender] == VoteType.Positive)
        {
            voteDelta -= 1;
        }else if(userVotes[storyId][msg.sender] == VoteType.Negative)
        {
            voteDelta += 1;
        }
        if(voteType == VoteType.Positive)
        {
            voteDelta += 1;
        }else if( voteType == VoteType.Negative)
        {
            voteDelta -= 1;
        }

        userVotes[storyId][msg.sender] = voteType;
    }

    function removeStoryReferences(uint storyId) internal
    {
        if(stories[storyId].previousStory != 0)
            stories[stories[storyId].previousStory].nextStory = stories[storyId].nextStory;
        if(stories[storyId].nextStory != 0)
            stories[stories[storyId].nextStory].previousStory = stories[storyId].previousStory;
    }

    function getAbsoluteValue(int value) internal pure returns(int)
    {
        if(value < 0)
            return 0-value;
        return value;
    }

    // Public functions

    function deleteStory(uint storyId) public
    {
        require(DELETE_STORIES_ALLOWED || owner() == msg.sender, "Create stories is not active");
        require(stories[storyId].creator == msg.sender || owner() == msg.sender, "You have not permissions to delete this story");
        removeStoryReferences(storyId);
        if(storyId == STORIES_HEAD)
        {
            STORIES_HEAD = stories[storyId].nextStory;
        }
        if(storyId == NEW_STORY_GOES_AROUND_HERE)
        {
            if(stories[storyId].nextStory != 0 &&
                (getAbsoluteValue(stories[stories[storyId].nextStory].votes - 1)
                <= getAbsoluteValue(stories[stories[storyId].previousStory].votes - 1)))
            {
                NEW_STORY_GOES_AROUND_HERE = stories[storyId].nextStory;
            }else if(stories[storyId].previousStory != 0)
            {
                NEW_STORY_GOES_AROUND_HERE = stories[storyId].previousStory;
            }else
            {
                revert("Can't delete last story");
            }
        }
        isStoryDeleted[storyId] = true;
    }

    function createStory(string memory title, string memory message, string memory image) public
    {
        require(IS_ACTIVE, "Create stories is not active");
        Story memory story;
        story.creator = msg.sender;
        story.title = title;
        story.message = message;
        story.image = image;
        story.votes = 1;
        story.timestamp = block.timestamp;
        stories[STORY_ID_MANAGER] = story;
        userVotes[STORY_ID_MANAGER][msg.sender] = VoteType.Positive;

        // Insert
        if(STORIES_HEAD == 0) // First element
        {
            STORIES_HEAD = STORY_ID_MANAGER;
        }else if(stories[NEW_STORY_GOES_AROUND_HERE].votes <= 1) // Insert before
        {
            if(stories[NEW_STORY_GOES_AROUND_HERE].previousStory != 0)
            {
                stories[stories[NEW_STORY_GOES_AROUND_HERE].previousStory].nextStory = STORY_ID_MANAGER;
                stories[STORY_ID_MANAGER].previousStory = stories[NEW_STORY_GOES_AROUND_HERE].previousStory;
            }
            stories[NEW_STORY_GOES_AROUND_HERE].previousStory = STORY_ID_MANAGER;
            stories[STORY_ID_MANAGER].nextStory = NEW_STORY_GOES_AROUND_HERE;

            if(NEW_STORY_GOES_AROUND_HERE == STORIES_HEAD) // Update head
                STORIES_HEAD = STORY_ID_MANAGER;
        }else // Insert after
        {
            if(stories[NEW_STORY_GOES_AROUND_HERE].nextStory != 0)
            {
                stories[stories[NEW_STORY_GOES_AROUND_HERE].nextStory].previousStory = STORY_ID_MANAGER;
                stories[STORY_ID_MANAGER].nextStory = stories[NEW_STORY_GOES_AROUND_HERE].nextStory;
            }
            stories[NEW_STORY_GOES_AROUND_HERE].nextStory = STORY_ID_MANAGER;
            stories[STORY_ID_MANAGER].previousStory = NEW_STORY_GOES_AROUND_HERE;
        }
        NEW_STORY_GOES_AROUND_HERE = STORY_ID_MANAGER; // Update where the next new story will go

        userStories[msg.sender][userStoriesCount[msg.sender]] = STORY_ID_MANAGER;
        userStoriesCount[msg.sender] +=1;

        STORY_ID_MANAGER += 1;
    }

    function setStoryVote(uint storyId, VoteType voteType, uint gasSaverIterator) public
    {
        require(IS_ACTIVE, "Create stories is not active");
        require(stories[storyId].creator != address(0), "Story must exist");
        int voteDelta = getVoteDelta(storyId, voteType);
        stories[storyId].votes += voteDelta;

        if(voteDelta > 0
            && stories[storyId].previousStory != 0
            && stories[storyId].votes > stories[stories[storyId].previousStory].votes) // move to previous
        {
            // Setup new NEW_STORY_GOES_AROUND_HERE
            if(storyId == NEW_STORY_GOES_AROUND_HERE)
            {
                if(stories[storyId].nextStory != 0)
                {
                    NEW_STORY_GOES_AROUND_HERE = stories[storyId].nextStory;
                }else
                {
                    NEW_STORY_GOES_AROUND_HERE = stories[storyId].previousStory;
                }
            }

            // Remove current references
            removeStoryReferences(storyId);
            
            // Look for spot to insert
            uint storyIterator = gasSaverIterator;
            if(gasSaverIterator == 0)
            {
                storyIterator = stories[storyId].previousStory;
                uint i;
                while(stories[storyIterator].previousStory != 0
                    && stories[stories[storyIterator].previousStory].votes < stories[storyId].votes)
                {
                    storyIterator = stories[storyIterator].previousStory;
                    i++;
                }
            }else {
                require(GAS_SAVER_ALLOWED, "Gas saver is not active");

                require(stories[storyIterator].previousStory == 0
                    || (stories[stories[storyIterator].previousStory].votes >= stories[storyId].votes
                        && (stories[storyIterator].nextStory == 0 ||
                            stories[stories[storyIterator].nextStory].votes <= stories[storyId].votes
                        )
                    ), "Invalid move to previous gas saver");
            }

            // Update Head
            if(storyIterator == STORIES_HEAD)
                STORIES_HEAD = storyId;

            // Insert
            stories[storyId].previousStory = stories[storyIterator].previousStory;
            stories[stories[storyIterator].previousStory].nextStory = storyId;
            stories[storyId].nextStory = storyIterator;
            stories[storyIterator].previousStory = storyId;
        }else if(voteDelta < 0
            && stories[storyId].nextStory != 0
            && stories[storyId].votes < stories[stories[storyId].nextStory].votes) // move to next
        {
            // Setup new NEW_STORY_GOES_AROUND_HERE
            if(storyId == NEW_STORY_GOES_AROUND_HERE)
            {
                if(stories[storyId].previousStory != 0)
                {
                    NEW_STORY_GOES_AROUND_HERE = stories[storyId].previousStory;
                }else
                {
                    NEW_STORY_GOES_AROUND_HERE = stories[storyId].nextStory;
                }
            }

            // Remove current references
            removeStoryReferences(storyId);
            
            // Look for spot to insert
            uint storyIterator = gasSaverIterator;
            if(gasSaverIterator == 0)
            {
                storyIterator = stories[storyId].nextStory;
                while(stories[storyIterator].nextStory != 0
                    && stories[stories[storyIterator].nextStory].votes > stories[storyId].votes)
                {
                    storyIterator = stories[storyIterator].nextStory;
                }
            }else {
                require(GAS_SAVER_ALLOWED, "Gas saver is not active");

                require(stories[storyIterator].nextStory == 0
                    || (stories[stories[storyIterator].nextStory].votes <= stories[storyId].votes
                        && (stories[storyIterator].previousStory == 0 ||
                            stories[stories[storyIterator].previousStory].votes >= stories[storyId].votes
                        )
                    ), "Invalid move to next gas saver");
            }

            // Update Head
            if(storyId == STORIES_HEAD)
                STORIES_HEAD = stories[storyId].nextStory;

            // Insert
            stories[storyId].nextStory = stories[storyIterator].nextStory;
            stories[stories[storyIterator].nextStory].previousStory = storyId;
            stories[storyId].previousStory = storyIterator;
            stories[storyIterator].nextStory = storyId;
        }
    }

    // Only owner functions

    function setContractActive(bool value) public onlyOwner
    {
        IS_ACTIVE = value;
    }

    function setDeleteStoriesAllowed(bool value) public onlyOwner
    {
        DELETE_STORIES_ALLOWED = value;
    }

    function setGasSaverAllowed(bool value) public onlyOwner
    {
        GAS_SAVER_ALLOWED = value;
    }
}