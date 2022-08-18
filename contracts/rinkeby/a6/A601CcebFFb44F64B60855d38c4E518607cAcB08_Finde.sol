// SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Utils.sol";

contract Finde is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public _providerIndexCounter;

    // EVENTS
    event TokenUpdated(address nvg8Token);
    event UriAdded(string uri, address provider, string[] tags);
    event UpVoted(
        address voter,
        address provider,
        uint256 upVotes,
        uint256 downVotes
    );
    event DownVoted(
        address voter,
        address provider,
        uint256 upVotes,
        uint256 downVotes
    );

    // STRUCTS
    struct Uri {
        string uri;
        string[] tags;
        string country;
        address provider;
    }
    struct Provider {
        uint256[] uriIndexes;
        Vote votes;
        address providerAddress;
        // mapping(string => uint256[]) countryToUriIndexes;
        mapping(string => uint256[]) tagToUriIndexes;
    }

    struct Vote {
        uint256 upVote;
        uint256 downVote;
    }

    struct Voter {
        uint256 lastVoteTime;
        mapping(address => bool) voted;
    }

    struct ProviderUriReturn {
        string uri;
    }
    struct UriReturn {
        string uri;
        address provider;
        string country;
        string[] tags;
        Vote votes;
    }

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
            voters[msg.sender].voted[_providerAddress] == false,
            "FINDE:  Already voted"
        );
        // check it's been more than `votingWaitTime` since the last vote
        require(
            voters[msg.sender].lastVoteTime + votingWaitTime < block.timestamp,
            "FINDE: Can't vote more than once within {votingWaitTime}"
        );
        _;
    }

    // TOKEN
    IERC20 private _token;

    mapping(string => bool) public availableTags;

    mapping(address => uint256) public addressToIndex; // address to index( that points to the provider)
    mapping(uint256 => Provider) public indexToProvider; // index to provider

    Uri[] public uris; // array of uris
    mapping(string => uint256[]) public countryToUriIndexes; // country to uri indexes
    mapping(string => uint256[]) public tagToUriIndexes; // tag to uri indexes
    mapping(string => mapping(string => uint256[]))
        public tagToCountryToUriIndexes; // tag to country to uri indexes

    mapping(address => Voter) public voters; // address to latest vote time

    uint256 public votingWaitTime;
    uint256 public requiredTokensForVote;

    // CONSTRUCTOR
    constructor(
        address _tokenAddress,
        uint256 _votingWaitTime,
        uint256 _requiredTokensForVote
    ) {
        _token = IERC20(_tokenAddress);
        _providerIndexCounter.increment(); // start counter from 1;

        // ? Should we make these changeable setters?
        votingWaitTime = _votingWaitTime;
        requiredTokensForVote = _requiredTokensForVote;
    }

    /**
    * @dev Validates if the tags are allowed. Its a public function, so front-end dev can use it to verify tags before adding URI.
    * @notice Validates if the tags are valid, as owner can allow/disallow tags.
    * @param _tags array of tags to validate
    * @return bool true if valid, false if not
    */
    function validateTags(string[] memory _tags) public view returns (bool) {
        for (uint256 i = 0; i < _tags.length; i++) {
            if (availableTags[_tags[i]] == false) {
                return false;
            }
        }
        return true;
    }


    /**
    * @dev Public function to add a URI.
    * @notice Adds a new URI to the list of URIs.
    * @param _uri URI to add
    * @param _tags array of tags to add
    * @param _country country of the URI
    */
    function addUri(
        string memory _uri,
        string memory _country,
        string[] memory _tags
    ) public {
        // validate if the uri is not empty
        require(
            compareStringsbyBytes(_uri, "") == false,
            "FINDE: URI is empty string"
        );
        // validate if country is not empty
        require(
            compareStringsbyBytes(_country, "") == false,
            "FINDE: Country is empty string"
        );
        // validate if tags is not empty
        require(_tags.length > 0, "FINDE: Tags is empty array");
        require(validateTags(_tags), "FINDE: Invalid tags");

        if (addressToIndex[msg.sender] == 0) {
            // if the address is not in the mapping, add it
            addressToIndex[msg.sender] = _providerIndexCounter.current();

            indexToProvider[_providerIndexCounter.current()]
                .providerAddress = msg.sender;
            indexToProvider[_providerIndexCounter.current()]
                .uriIndexes = new uint256[](0);
            indexToProvider[_providerIndexCounter.current()].votes = Vote(0, 0);

            _providerIndexCounter.increment();
        }

        // add the uri to the array
        indexToProvider[addressToIndex[msg.sender]].uriIndexes.push(
            uris.length
        );
        countryToUriIndexes[_country].push(uris.length);

        for (uint256 i = 0; i < _tags.length; i++) {
            tagToUriIndexes[_tags[i]].push(uris.length);
            tagToCountryToUriIndexes[_tags[i]][_country].push(uris.length);

            indexToProvider[addressToIndex[msg.sender]]
                .tagToUriIndexes[_tags[i]]
                .push(uris.length);
        }

        uris.push(Uri(_uri, _tags, _country, msg.sender));

        // emit event
        emit UriAdded(_uri, msg.sender, _tags);
    }

    /**
    * @dev Private function to get a URIs based on offset and limit.
    * @param _offset offset of the URIs to get
    * @param _limit limit of the URIs to get
    * @return array of UriReturn struct
    */
    function _getUris(uint256 _offset, uint256 _limit)
        private
        view
        returns (UriReturn[] memory)
    {
        if (uris.length == 0) {
            return new UriReturn[](0);
        }
        require(
            _offset + _limit <= uris.length,
            "FINDE: Invalid offset and limit. _getUris"
        );
        UriReturn[] memory data = new UriReturn[](_limit);
        // if country and tag are empty, return all uris

        for (uint256 i = _offset; i < _offset + _limit; i++) {
            data[i - _offset] = UriReturn({
                uri: uris[i].uri,
                provider: uris[i].provider,
                country: uris[i].country,
                tags: uris[i].tags,
                votes: indexToProvider[addressToIndex[uris[i].provider]].votes
            });
        }

        return data;
    }

    /**
    * @dev Private function to get a URIs based on country alongside offset and limit.
    * @param _offset offset of the URIs to get
    * @param _limit limit of the URIs to get
    * @param _country country of the URIs to get
    * @return array of UriReturn struct
    */
    function _getUrisByCountry(
        uint256 _offset,
        uint256 _limit,
        string calldata _country
    ) private view returns (UriReturn[] memory) {
        // require(
        //     compareStringsbyBytes(_country, "") == false,
        //     "FINDE: Invalid country."
        // );
        if (countryToUriIndexes[_country].length == 0) {
            return new UriReturn[](0);
        }

        require(
            _offset + _limit <= countryToUriIndexes[_country].length,
            "FINDE: Invalid offset and limit. _getUrisByCountry"
        );

        UriReturn[] memory data = new UriReturn[](_limit);

        for (uint256 i = _offset; i < _offset + _limit; i++) {
            data[i - _offset] = UriReturn({
                uri: uris[countryToUriIndexes[_country][i]].uri,
                provider: uris[countryToUriIndexes[_country][i]].provider,
                country: uris[countryToUriIndexes[_country][i]].country,
                tags: uris[countryToUriIndexes[_country][i]].tags,
                votes: indexToProvider[
                    addressToIndex[
                        uris[countryToUriIndexes[_country][i]].provider
                    ]
                ].votes
            });
        }

        return data;
    }

    /**
    * @dev Private function to get a URIs based on tag alongside offset and limit.
    * @param _offset offset of the URIs to get
    * @param _limit limit of the URIs to get
    * @param _tag tag of the URIs to get
    * @return array of UriReturn struct
    */
    function _getUrisByTag(
        uint256 _offset,
        uint256 _limit,
        string calldata _tag
    ) private view returns (UriReturn[] memory) {
        // require(
        //     compareStringsbyBytes(_tag, "") == false,
        //     "FINDE: Invalid tag."
        // );
        if (tagToUriIndexes[_tag].length == 0) {
            return new UriReturn[](0);
        }
        require(
            _offset + _limit <= tagToUriIndexes[_tag].length,
            "FINDE: Invalid offset and limit. _getUrisByTag"
        );

        UriReturn[] memory data = new UriReturn[](_limit);

        for (uint256 i = _offset; i < _offset + _limit; i++) {
            data[i - _offset] = UriReturn({
                uri: uris[tagToUriIndexes[_tag][i]].uri,
                provider: uris[tagToUriIndexes[_tag][i]].provider,
                country: uris[tagToUriIndexes[_tag][i]].country,
                tags: uris[tagToUriIndexes[_tag][i]].tags,
                votes: indexToProvider[
                    addressToIndex[uris[tagToUriIndexes[_tag][i]].provider]
                ].votes
            });
        }

        return data;
    }

    /**
    * @dev Private function to get a URIs based on tag and country alongside offset and limit.
    * @param _offset offset of the URIs to get
    * @param _limit limit of the URIs to get
    * @param _tag tag of the URIs to get
    * @param _country country of the URIs to get
    * @return array of UriReturn struct
    */
    function _getUrisByTagAndCountry(
        uint256 _offset,
        uint256 _limit,
        string calldata _country,
        string calldata _tag
    ) private view returns (UriReturn[] memory) {
        // if country and tag are not empty
        // require(
        //     compareStringsbyBytes(_country, "") == false ||
        //         compareStringsbyBytes(_tag, "") == false,
        //     "FINDE: Invalid country or tag."
        // );
        if (tagToCountryToUriIndexes[_tag][_country].length == 0) {
            return new UriReturn[](0);
        }
        require(
            _offset + _limit <= tagToCountryToUriIndexes[_tag][_country].length,
            "FINDE: Invalid offset and limit. _getUrisByTagAndCountry"
        );

        UriReturn[] memory data = new UriReturn[](_limit);

        for (uint256 i = _offset; i < _offset + _limit; i++) {
            data[i - _offset] = UriReturn({
                uri: uris[tagToCountryToUriIndexes[_tag][_country][i]].uri,
                provider: uris[tagToCountryToUriIndexes[_tag][_country][i]]
                    .provider,
                country: uris[tagToCountryToUriIndexes[_tag][_country][i]]
                    .country,
                tags: uris[tagToCountryToUriIndexes[_tag][_country][i]].tags,
                votes: indexToProvider[
                    addressToIndex[
                        uris[tagToCountryToUriIndexes[_tag][_country][i]]
                            .provider
                    ]
                ].votes
            });
        }

        return data;
    }

    /**
    * @dev Public function to get a URIs based on tag and country and provider alongside offset and limit.
    * @param _offset offset of the URIs to get
    * @param _limit limit of the URIs to get
    * @param _tag tag of the URIs to get
    * @param _country country of the URIs to get
    * @return array of UriReturn struct
    */
    function getPaginatedUris(
        uint256 _offset,
        uint256 _limit,
        string calldata _country,
        string calldata _tag
    ) public view returns (UriReturn[] memory) {
        require(_limit > 0 && _limit <= 100, "FINDE: Invalid limit.");

        if (
            compareStringsbyBytes(_country, "") == false &&
            compareStringsbyBytes(_tag, "") == false
        ) {
            return _getUrisByTagAndCountry(_offset, _limit, _country, _tag);
        } else if (
            compareStringsbyBytes(_country, "") == true &&
            compareStringsbyBytes(_tag, "") == false
        ) {
            return _getUrisByTag(_offset, _limit, _tag);
        } else if (
            compareStringsbyBytes(_country, "") == false &&
            compareStringsbyBytes(_tag, "") == true
        ) {
            return _getUrisByCountry(_offset, _limit, _country);
        } else {
            return _getUris(_offset, _limit);
        }
    }

    /**
    * @dev Public function to get a URIs based on provider address alongside offset and limit.
    * @param _offset offset of the URIs to get
    * @param _limit limit of the URIs to get
    * @param _provider address of the provider
    * @return array of ProviderUriReturn struct
    */

    function getProviderUris(
        uint256 _offset,
        uint256 _limit,
        address _provider
    ) public view returns (ProviderUriReturn[] memory) {
        // check if provider is valid
        require(_provider != address(0), "FINDE: Invalid provider.");
        // check if limit and offset are valid
        require(
            indexToProvider[addressToIndex[_provider]].uriIndexes.length <=
                _offset + _limit &&
                _offset >= 0 &&
                _limit <= 100,
            "FINDE: Invalid offset and limit."
        );
        // create array of uris
        ProviderUriReturn[] memory data = new ProviderUriReturn[](_limit);
        // get uris from provider
        for (uint256 i = _offset; i < _offset + _limit; i++) {
            data[i - _offset] = ProviderUriReturn(
                uris[indexToProvider[addressToIndex[_provider]].uriIndexes[i]]
                    .uri
            );
        }
        return data;
    }

    /**
    * @dev Public function to get a URIs based on provider address and tag alongside offset and limit.
    * @param _offset offset of the URIs to get
    * @param _limit limit of the URIs to get
    * @param _provider address of the provider
    * @param _tag tag to get URIs by
    * @return array of ProviderUriReturn struct
    */
    function getProviderUris(
        uint256 _offset,
        uint256 _limit,
        address _provider,
        string memory _tag
    ) public view returns (ProviderUriReturn[] memory) {
        // check if provider is valid
        require(_provider != address(0), "FINDE: Invalid provider.");
        require(
            compareStringsbyBytes(_tag, "") == false,
            "FINDE: Invalid tag."
        );
        require(
            _offset >= 0 && _limit <= 100,
            "FINDE: Invalid offset and limit."
        );

        ProviderUriReturn[] memory data = new ProviderUriReturn[](_limit);

        if (
            indexToProvider[addressToIndex[_provider]]
                .tagToUriIndexes[_tag]
                .length == 0
        ) {
            return new ProviderUriReturn[](0);
        }

        require(
            _offset + _limit <=
                indexToProvider[addressToIndex[_provider]]
                    .tagToUriIndexes[_tag]
                    .length,
            "FINDE: Invalid offset and limit."
        );

        for (uint256 i = _offset; i < _offset + _limit; i++) {
            data[i - _offset] = ProviderUriReturn(
                uris[
                    indexToProvider[addressToIndex[_provider]].tagToUriIndexes[
                        _tag
                    ][i]
                ].uri
            );
        }
        return data;
    }

    /**
    * @dev Public function to add a tag in allowed tags. Only contract owner call call this.
    * @notice Allow a tag, so Providers can select this as a tag/interest while adding URIs.
    * @param _tag tag to add
    */
    function allowTag(string calldata _tag) public onlyOwner {
        require(
            compareStringsbyBytes(_tag, "") == false,
            "FINDE: Invalid tag."
        );
        availableTags[_tag] = true;
    }

    /**
    * @dev Public function to remove a tag from allowed tags. Only contract owner call call this.
    * @notice Remove a tag, so Providers can no longer select this as a tag/interest while adding URIs.
    * @param _tag tag to remove
    */
    function disallowTag(string calldata _tag) public onlyOwner {
        require(
            compareStringsbyBytes(_tag, "") == false,
            "FINDE: Invalid tag."
        );
        availableTags[_tag] = false;
    }

    /** updateToken
    * @dev Public function to update the erc20 token address. Only contract owner call call this.
    * @notice Update the erc20 token address, that is used to verify the eligibility of a user while voting.
    * @param _tokenAddress address of the erc20 contract to update
    */

    function updateToken(address _tokenAddress) public onlyOwner {
        _token = IERC20(_tokenAddress);

        // emit event
        emit TokenUpdated(_tokenAddress);
    }

    /**
     * @dev Read the FindeToken balance of a wallet.
     * @param _address Wallet address.
     * @return The FindeToken balance of the wallet.
     */
    function readTokenBalance(address _address) public view returns (uint256) {
        return _token.balanceOf(_address);
    }

    /**
     * @dev DownVote a provider.
     * @dev Emit a DownVoted event with the provider's address, URI, block.timestamp, upvote count, downvote count.
     * @param _providerAddress Address of the provider.
     */
    function downVoteProvider(address _providerAddress)
        external
        EligibleToVote(_providerAddress)
    {
        indexToProvider[addressToIndex[_providerAddress]].votes.downVote += 1;
        // voterTimeRecord[msg.sender] = block.timestamp;
        // providerVoters[_providerAddress][msg.sender].downVote += 1;
        voters[msg.sender].lastVoteTime = block.timestamp;
        voters[msg.sender].voted[_providerAddress] = true;

        emit DownVoted(
            msg.sender,
            _providerAddress,
            indexToProvider[addressToIndex[_providerAddress]].votes.upVote,
            indexToProvider[addressToIndex[_providerAddress]].votes.downVote
        );
    }

    /**
     * @dev UpVote a provider.
     * @dev Emit a UpVote event with the provider's address, URI, block.timestamp, upvote count, downvote count.
     * @param _providerAddress Address of the provider.
     */
    function upVoteProvider(address _providerAddress)
        external
        EligibleToVote(_providerAddress)
    {
        indexToProvider[addressToIndex[_providerAddress]].votes.upVote += 1;
        voters[msg.sender].lastVoteTime = block.timestamp;
        voters[msg.sender].voted[_providerAddress] = true;

        emit UpVoted(
            msg.sender,
            _providerAddress,
            indexToProvider[addressToIndex[_providerAddress]].votes.upVote,
            indexToProvider[addressToIndex[_providerAddress]].votes.downVote
        );
    }

    /**
     * @dev Get the votes of a provider.
     * @param _providerAddress Address of the provider.
     * @return The votes of the provider as a Vote struct.
     */
    function getProviderVotes(address _providerAddress)
        external
        view
        returns (Vote memory)
    {
        return indexToProvider[addressToIndex[_providerAddress]].votes;
    }

    /**
     * @dev Get the remaining time for a voter to vote.
     * @param _voter Address of the voter.
     * @return The remaining time for a voter to vote.
     */
    function getRemainingTimeForVote(address _voter)
        external
        view
        returns (int256)
    {
        int256 timeLeft = int256(
            voters[_voter].lastVoteTime + votingWaitTime - block.timestamp
        );
        if (timeLeft < 0) {
            return 0;
        }
        return timeLeft;
    }

    /**
     * @dev Get the number of URIs of a country.
     * @param _country Country name.
     * @return The number of URIs of a country.
     */
    function _getCountryUrisLength(string memory _country)
        private
        view
        returns (uint256)
    {
        return countryToUriIndexes[_country].length;
    }

    /**
     * @dev Function to get the length of uris with a specific tag.
     * @param _tag The tag to get the length of uris.
     * @return The length of uris with the specific tag.
     */
    function _getTagUrisLength(string memory _tag)
        private
        view
        returns (uint256)
    {
        return tagToUriIndexes[_tag].length;
    }

    /**
     * @dev Function to get the length of uris with a specific tag and country.
     * @param _tag The tag to get the length of uris.
     * @param _country The country to get the length of uris.
     * @return The length of uris with the specific tag and country.
     */
    function _getTagCountryUrisLength(
        string memory _tag,
        string memory _country
    ) private view returns (uint256) {
        return tagToCountryToUriIndexes[_tag][_country].length;
    }

    /**
    * @dev Public function to get the length of uris.
    * @param _tag tag to get the length of uris.
    * @param _country country to get the length of uris.
    * @return The length of uris with the specific tag and country.
    */
    function getUrisLength(string memory _tag, string memory _country)
        external
        view
        returns (uint256)
    {
        if (
            compareStringsbyBytes(_tag, "") == true &&
            compareStringsbyBytes(_country, "") == true
        ) {
            return uris.length; //
        } else if (
            compareStringsbyBytes(_tag, "") == true &&
            compareStringsbyBytes(_country, "") == false
        ) {
            return _getCountryUrisLength(_country);
        } else if (
            compareStringsbyBytes(_tag, "") == false &&
            compareStringsbyBytes(_country, "") == true
        ) {
            return _getTagUrisLength(_tag);
        } else {
            // when both tag and country are not empty
            return _getTagCountryUrisLength(_tag, _country);
        }
    }

    /**
    * @dev Public function to get the length of all uris of a provider.
    * @param _providerAddress Address of the provider.
    * @return The length of all uris of a provider.
    */
    function getProviderUrisLength(address _providerAddress)
        external
        view
        returns (uint256)
    {
        return
            indexToProvider[addressToIndex[_providerAddress]].uriIndexes.length;
    }

    /**
     * @dev Public function to get the length of uris of a provider based on a tag.
     * @param _providerAddress Address of the provider.
     * @param _tag The tag to get the length of uris.
     * @return (uint256) The length of uris of a provider.
     */
    function getProviderUrisLength(address _providerAddress, string memory _tag)
        external
        view
        returns (uint256)
    {
        return
            indexToProvider[addressToIndex[_providerAddress]]
                .tagToUriIndexes[_tag]
                .length;
    }
}

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;

function compareStringsbyBytes(string memory s1, string memory s2)
    pure
    returns (bool)
{
    return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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