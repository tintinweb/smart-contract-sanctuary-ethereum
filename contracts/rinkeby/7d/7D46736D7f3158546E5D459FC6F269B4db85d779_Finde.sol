// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Finde {
    using Counters for Counters.Counter;
    Counters.Counter public _uriIndexCounter;


    // EVENTS
    event UriAdded(string indexed uri, address indexed provider);
    event UpVoted(address indexed voter, address indexed provider, uint256 time);
    event DownVoted(address indexed voter, address indexed provider, uint256 time);

    // STRUCTS
    struct Provider {
        string uri;
        Vote votes;
        address addr;
        // uint256 lastVoteTime;//
        string country;
        uint256 countryLocalIndex; // index in the country array
    }

    struct Vote {
        uint256 upVote;
        uint256 downVote;
    }

    // TOKEN
    IERC20 private _token;

    // STATE VARIABLES
    mapping(string => uint256[]) public countryToIndexs; // country to [indexs]
    mapping(address => uint256) public addressToIndex; // address to index( that points to the provider)

    mapping(uint256 => Provider) public indexToProvider; // index to provider
    mapping(address => mapping(address => Vote)) public providerVoters; // provider => voter => vote
    mapping(address => uint256) public voterTimeRecord; // to keep record of the time of the last vote

    uint256 public votingWaitTime;
    uint256 public requiredTokensForVote;
    
    // MODIFIERS
    modifier EligibleToVote(address _providerAddress) {
        // validate if voter has enough tokens
        require(
            _token.balanceOf(msg.sender) >= requiredTokensForVote,
            "FINDE: Insufficient token balance"
        );
        // validate if the provider is already in the list
        require(
            addressToIndex[_providerAddress] != 0,
            "FINDE: Invalid provider address"
        );
        // _providerAddress and msg.sender should not be the same
        require(
            _providerAddress != msg.sender,
            "FINDE: Cannot vote for yourself"
        );
        // validate if voter has already voted
        require(
            providerVoters[_providerAddress][msg.sender].upVote < 1 &&
                providerVoters[_providerAddress][msg.sender].downVote < 1,
            "FINDE:  Already voted"
        );
        // check it's been more than `votingWaitTime` since the last vote
        require(
            voterTimeRecord[msg.sender] + votingWaitTime < block.timestamp,
            "FINDE: Can't vote more than once within {votingWaitTime}"
        );

        _;
    }

    // CONSTRUCTOR
    constructor(address _tokenAddress) {
        _token = IERC20(_tokenAddress);
        _uriIndexCounter.increment(); // start counter from 1;

        votingWaitTime = 1 minutes;
        requiredTokensForVote = 100;
    }

    // FUNCTIONS
    function addURI(string memory _uri, string memory _country) public {
        if (addressToIndex[msg.sender] == 0) {
            indexToProvider[_uriIndexCounter.current()] = Provider(
                _uri,
                Vote(0, 0),
                msg.sender,
                _country,
                countryToIndexs[_country].length
            );
            addressToIndex[msg.sender] = _uriIndexCounter.current();
            // add to country index
            countryToIndexs[_country].push(_uriIndexCounter.current());

            _uriIndexCounter.increment();
        } else {
            // remove provider index from old country and add to new country
            if (
                compareStringsbyBytes(
                    indexToProvider[addressToIndex[msg.sender]].country,
                    _country
                ) == false
            ) {
                delete countryToIndexs[
                    indexToProvider[addressToIndex[msg.sender]].country
                ][indexToProvider[addressToIndex[msg.sender]].countryLocalIndex];

                indexToProvider[addressToIndex[msg.sender]]
                    .countryLocalIndex = countryToIndexs[_country].length;
                indexToProvider[addressToIndex[msg.sender]].country = _country;

                countryToIndexs[_country].push(addressToIndex[msg.sender]);
            }
            // update provider uri
            indexToProvider[addressToIndex[msg.sender]].uri = _uri;
        }

        emit UriAdded(_uri, msg.sender);
    }

    function getPaginatedURIs(
        uint256 _offset,
        uint256 _limit,
        string calldata _country
    ) external view returns (Provider[] memory) {
        require(_limit > 0 && _limit <= 100, "FINDE: Invalid limit.");
        require(_offset < _uriIndexCounter.current(), "FINDE: Invalid offset.");
        require(
            _offset + _limit <= _uriIndexCounter.current(),
            "FINDE: Invalid offset and limit."
        );

        Provider[] memory data = new Provider[](_limit);

        uint256 dataLength = 0;

        if (compareStringsbyBytes(_country, "")) {
            _offset = _offset + 1; // increase offset by 1 as _uriIndexCounter starts from 1

            // no country filter
            for (uint256 i = _offset; i < _offset + _limit; i++) {
                if (compareStringsbyBytes(indexToProvider[i].uri, "") == false) {
                    // if the uri is not empty
                    data[dataLength] = indexToProvider[i];
                    dataLength++;
                }
            }
        } else {
            // country filter
            require(
                countryToIndexs[_country].length > 0,
                "FINDE: Invalid country."
            );
            require(
                countryToIndexs[_country].length >= _offset + _limit,
                "FINDE: Invalid offset and limit."
            );
            for (uint256 i = _offset; i < _offset + _limit; i++) {
                if (countryToIndexs[_country][i] != 0) {
                    data[dataLength] = indexToProvider[countryToIndexs[_country][i]];
                    dataLength++;
                }
            }
        }
        
        return data;
    }

    // function upVoteProvider(address _providerAddress) external ValidTokenBalance AddressFound(_providerAddress) VotingTimeOut EligibleToVote(_providerAddress){
    function upVoteProvider(address _providerAddress)
        external
        EligibleToVote(_providerAddress)
    {
        indexToProvider[addressToIndex[_providerAddress]].votes.upVote += 1;
        voterTimeRecord[msg.sender] = block.timestamp;
        providerVoters[_providerAddress][msg.sender].upVote += 1;
        
        emit UpVoted(msg.sender, _providerAddress, block.timestamp );
    }

    function downVoteProvider(address _providerAddress)
        external
        EligibleToVote(_providerAddress)
    {
        indexToProvider[addressToIndex[_providerAddress]].votes.downVote += 1;
        voterTimeRecord[msg.sender] = block.timestamp;
        providerVoters[_providerAddress][msg.sender].downVote += 1;

        emit DownVoted(msg.sender, _providerAddress, block.timestamp );
    }

    function getProviderVotes(address _providerAddress)
        external
        view
        returns (Vote memory)
    {
        return indexToProvider[addressToIndex[_providerAddress]].votes;
    }

    function readTokenBalance(address _account)
        external
        view
        returns (uint256)
    {
        return _token.balanceOf(_account);
    }

    function getRemainingTimeForVote() external view returns (int256) {
        int256 timeLeft = int256((voterTimeRecord[msg.sender] + votingWaitTime) - block.timestamp );
        if (timeLeft >= 0) {
            return timeLeft;
        }
        return 0;
    }

    function compareStringsbyBytes(string memory s1, string memory s2)
        private
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function getCountryUrisLength(string memory _country)
        external
        view
        returns (uint256)
    {
        return countryToIndexs[_country].length;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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