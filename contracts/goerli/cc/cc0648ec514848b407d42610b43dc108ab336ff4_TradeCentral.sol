// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TradeCentral is ReentrancyGuard {
    //@dev global variables
    address public owner;

    struct userData {
        string email;
        string name;
        string image;
    }

    mapping(address => userData) public usersMap;
    address[] public users;

    // trade structs
    struct TradeData {
        uint256 id;
        address buyer;
        address seller;
        uint256 price;
        string description;
        string image;
        string[] name;
        string[] category;
        string[] country;
        bool isSold;
        bool staking;
    }
    uint256 public tradeCount = 0;
    mapping(uint256 => TradeData) public tradesMap;
    // store the trade ids for each name, category and country
    mapping(bytes32 => uint256[]) public nameToTradeId;
    string[] public names;
    mapping(bytes32 => uint256[]) public categoryToTradeIds;
    string[] public categories;
    mapping(bytes32 => uint256[]) public countryToTradeIds;
    string[] public countries;

    function getTotalTrades() public view returns (uint256) {
        return tradeCount;
    }

    function getTotalUsers() public view returns (uint256) {
        return users.length;
    }

    function getTradesByName(string memory _name)
        public
        view
        returns (uint256[] memory)
    {
        return nameToTradeId[keccak256(abi.encodePacked(_name))];
    }

    function getTradesByCategory(string memory _category)
        public
        view
        returns (uint256[] memory)
    {
        return categoryToTradeIds[keccak256(abi.encodePacked(_category))];
    }

    function getTradesByCountry(string memory _country)
        public
        view
        returns (uint256[] memory)
    {
        return countryToTradeIds[keccak256(abi.encodePacked(_country))];
    }

    // function that returns and array of the names of all countries, and the serialized name in the same array
    function getCountries() public view returns (string[][] memory) {
        string[][] memory result = new string[][](countries.length);
        if (countries.length == 0) {
            return result;
        }

        for (uint256 i = 0; i < countries.length; i++) {
            result[i] = new string[](2);
            result[i][0] = countries[i];
            result[i][1] = tradesMap[
                countryToTradeIds[keccak256(abi.encodePacked(countries[i]))][0]
            ].country[1];
        }
        return result;
    }

    function getCategories() public view returns (string[][] memory) {
        string[][] memory result = new string[][](categories.length);
        if (categories.length == 0) {
            return result;
        }

        for (uint256 i = 0; i < categories.length; i++) {
            result[i] = new string[](2);
            result[i][0] = categories[i];
            result[i][1] = tradesMap[
                categoryToTradeIds[keccak256(abi.encodePacked(categories[i]))][
                    0
                ]
            ].category[1];
        }
        return result;
    }

    function getSearchTerm(string memory _term)
        public
        view
        returns (string memory)
    {
        // this will try to guess what the user is searching for, and return the real name, category or country
        bytes32 termHash = keccak256(abi.encodePacked(_term));

        if (categoryToTradeIds[termHash].length > 0) {
            return tradesMap[categoryToTradeIds[termHash][0]].category[1];
        }

        if (countryToTradeIds[termHash].length > 0) {
            return tradesMap[countryToTradeIds[termHash][0]].country[1];
        }

        if (nameToTradeId[termHash].length > 0) {
            return tradesMap[nameToTradeId[termHash][0]].name[1];
        }

        // if we get here, we didn't find anything, so return the original term
        return _term;
    }

    function searchTrades(
        string memory _country,
        string memory _category,
        string memory _name
    ) public view returns (uint256[] memory) {
        // if country is not empty, start with country
        uint256[] memory results;
        if (bytes(_country).length > 0) {
            results = getTradesByCountry(_country);
        }
        if (bytes(_category).length > 0) {
            uint256[] memory categoryResults = getTradesByCategory(_category);
            // if country is not empty, get the intersection of the two
            if (bytes(_country).length > 0) {
                uint256[] memory temp = new uint256[](results.length);
                uint256 count = 0;
                for (uint256 i = 0; i < results.length; i++) {
                    for (uint256 j = 0; j < categoryResults.length; j++) {
                        if (results[i] == categoryResults[j]) {
                            temp[count] = results[i];
                            count++;
                        }
                    }
                }
                results = new uint256[](count);
                for (uint256 i = 0; i < count; i++) {
                    results[i] = temp[i];
                }
            } else {
                results = categoryResults;
            }
        }
        if (bytes(_name).length > 0) {
            // get the results from name, if there are any results from country or category, get the intersection
            uint256[] memory nameResults = getTradesByName(_name);
            if (results.length > 0) {
                uint256[] memory temp = new uint256[](results.length);
                uint256 count = 0;
                for (uint256 i = 0; i < results.length; i++) {
                    for (uint256 j = 0; j < nameResults.length; j++) {
                        if (results[i] == nameResults[j]) {
                            temp[count] = results[i];
                            count++;
                        }
                    }
                }
                results = new uint256[](count);
                for (uint256 i = 0; i < count; i++) {
                    results[i] = temp[i];
                }
            } else {
                results = nameResults;
            }
        }

        if (results.length > 0) {
            return results;
        }
        return new uint256[](0);
    }

    function getTradesByIds(uint256[] memory ids)
        public
        view
        returns (TradeData[] memory)
    {
        require(ids.length > 0, "Invalid ids");
        TradeData[] memory result = new TradeData[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            if (tradesMap[ids[i]].id == 0) {
                revert("Invalid id");
            }
            result[i] = tradesMap[ids[i]];
        }
        return result;
    }

    // @dev function to get all tradesMap results from search
    function searchTradesByAll(
        string memory _country,
        string memory _category,
        string memory _name
    ) public view returns (TradeData[] memory) {
        require(
            bytes(_country).length > 0 ||
                bytes(_category).length > 0 ||
                bytes(_name).length > 0,
            "Invalid search"
        );
        uint256[] memory ids = searchTrades(_country, _category, _name);
        if (ids.length == 0) {
            return new TradeData[](0);
        }
        return getTradesByIds(ids);
    }

    //@dev constructor
    constructor() {
        owner = msg.sender;
    }

    //@dev function create user with image
    function createUser(
        string memory _email,
        string memory _name,
        string memory _image
    ) external nonReentrant {
        require(msg.sender != address(0), "Invalid address");
        require(bytes(_email).length > 0, "Invalid email");
        require(bytes(_name).length > 0, "Invalid name");

        if (bytes(usersMap[msg.sender].email).length > 0) {
            revert("User already exists");
        }

        // use a placeholder image hash by default
        if (bytes(_image).length == 0) {
            _image = "placeholder";
        }

        usersMap[msg.sender] = userData(_email, _name, _image);
        users.push(msg.sender);
    }

    function normalizeString(string memory input)
        public
        pure
        returns (string memory)
    {
        bytes memory output = new bytes(bytes(input).length);
        // remplace white spaces and any other character that are not a letter or a number by a dash
        for (uint256 i = 0; i < bytes(input).length; i++) {
            if (bytes(input)[i] == 0x20) {
                output[i] = 0x2D;
            } else if (
                (bytes(input)[i] >= 0x30 && bytes(input)[i] <= 0x39) ||
                (bytes(input)[i] >= 0x41 && bytes(input)[i] <= 0x5A) ||
                (bytes(input)[i] >= 0x61 && bytes(input)[i] <= 0x7A)
            ) {
                output[i] = bytes(input)[i];
            } else {
                output[i] = 0x2D;
            }
        }

        // remplace uppercase by lowercase
        for (uint256 i = 0; i < bytes(output).length; i++) {
            if (bytes(output)[i] >= 0x41 && bytes(output)[i] <= 0x5A) {
                output[i] = bytes1(uint8(bytes(output)[i]) + 32);
            }
        }

        uint256 count = 0;
        // remove starting and ending dashes, and double dashes
        for (uint256 i = 0; i < bytes(output).length; i++) {
            if (
                (bytes(output)[i] == 0x2D && i == 0) ||
                (bytes(output)[i] == 0x2D && bytes(output)[i - 1] == 0x2D) ||
                (bytes(output)[i] == 0x2D && i == bytes(output).length)
            ) {
                count++;
            }
        }
        bytes memory temp = new bytes(bytes(output).length - count);
        // copy the array characteres to a new one without the dashes
        uint256 j = 0;
        for (uint256 i = 0; i < bytes(output).length; i++) {
            if (
                (bytes(output)[i] == 0x2D && i == 0) ||
                (bytes(output)[i] == 0x2D && bytes(output)[i - 1] == 0x2D) ||
                (bytes(output)[i] == 0x2D && i == bytes(output).length)
            ) {
                continue;
            } else {
                temp[j] = bytes(output)[i];
                j++;
            }
        }
        return string(temp);

        // return string(output);
    }

    //@dev function create one trade
    function createTrade(
        uint256 _price,
        string memory _name,
        string memory _description,
        string memory _category,
        string memory _country,
        string memory _image
    ) external nonReentrant {
        require(msg.sender != address(0), "Invalid address");
        require(_price > 0, "Invalid price");
        require(bytes(_name).length > 0, "Invalid name");
        require(bytes(_description).length > 0, "Invalid description");
        // require(bytes(_image).length > 0, "Invalid image");
        require(bytes(_category).length > 0, "Invalid category");
        require(bytes(_country).length > 0, "Invalid country");
        // the name is max 120 characters
        require(bytes(_name).length <= 120, "Max 120 characters for name");
        require(
            bytes(_category).length <= 30,
            "Max 30 characters for category"
        );
        require(bytes(_country).length <= 30, "Max 30 characters for country");
        
        if (bytes(_image).length == 0) {
            _image = "QmX54vAab7hFB2XXuH9v1mcMLm2VyvbH5R65hSB7qytebZ";
        }
        
        // create SEO friendly name, category and country, no special characters, we store the original name, category and country in the mapping
        string memory _clean_name = normalizeString(_name);
        string memory _clean_category = normalizeString(_category);
        string memory _clean_country = normalizeString(_country);
        string[] memory _indexed_name = new string[](2);
        _indexed_name[0] = _clean_name;
        _indexed_name[1] = _name;
        string[] memory _indexed_category = new string[](2);
        _indexed_category[0] = _clean_category;
        _indexed_category[1] = _category;
        string[] memory _indexed_country = new string[](2);
        _indexed_country[0] = _clean_country;
        _indexed_country[1] = _country;


        tradeCount++;
        uint256 _tradeId = tradeCount;
        tradesMap[_tradeId] = TradeData(
            _tradeId,
            address(0), // reserved for buyer
            msg.sender, // seller
            _price,
            _description,
            _image,
            _indexed_name,
            _indexed_category,
            _indexed_country,
            false, // isSold
            false // staking
        );

        nameToTradeId[keccak256(abi.encodePacked(_clean_name))].push(_tradeId);
        if (
            nameToTradeId[keccak256(abi.encodePacked(_clean_name))].length == 1
        ) {
            names.push(_clean_name);
        }
        categoryToTradeIds[keccak256(abi.encodePacked(_clean_category))].push(
            _tradeId
        );
        if (
            categoryToTradeIds[keccak256(abi.encodePacked(_clean_category))]
                .length == 1
        ) {
            categories.push(_clean_category);
        }
        countryToTradeIds[keccak256(abi.encodePacked(_clean_country))].push(
            _tradeId
        );
        if (
            countryToTradeIds[keccak256(abi.encodePacked(_clean_country))]
                .length == 1
        ) {
            countries.push(_clean_country);
        }
    }

    //@dev function for update profile user
    function updateProfile(
        string memory _email,
        string memory _name,
        string memory _image
    ) external nonReentrant {
        require(
            bytes(usersMap[msg.sender].email).length > 0,
            "User does not exist"
        );
        require(msg.sender != address(0), "Invalid address");
        require(bytes(_email).length > 0, "Invalid email");
        require(bytes(_name).length > 0, "Invalid name");
        if (bytes(_image).length == 0) {
            _image = "";
        }

        usersMap[msg.sender].email = _email;
        usersMap[msg.sender].name = _name;
        usersMap[msg.sender].image = _image;
    }

    // update profile without image
    function updateProfile(string memory _email, string memory _name)
        external
        nonReentrant
    {
        require(
            bytes(usersMap[msg.sender].email).length > 0,
            "User does not exist"
        );
        require(msg.sender != address(0), "Invalid address");
        require(bytes(_email).length > 0, "Invalid email");
        require(bytes(_name).length > 0, "Invalid name");
        usersMap[msg.sender].email = _email;
        usersMap[msg.sender].name = _name;
    }

    //@dev function for look tradesMap in the market by id
    function lookTrades(uint256 _itemId)
        public
        view
        returns (TradeData memory)
    {
        // validate that trade exists
        require(_itemId > 0 && _itemId <= tradeCount, "Trade does not exist");
        TradeData storage _trade = tradesMap[_itemId];
        return _trade;
    }

    // @dev function for look all open tradesMap in the market
    function lookAllTrades() public view returns (TradeData[] memory) {
        // validate that trade exists, if not return empty array
        if (tradeCount == 0) {
            return new TradeData[](0);
        }

        TradeData[] memory _tradesMap = new TradeData[](tradeCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= tradeCount; i++) {
            if (tradesMap[i].isSold == false) {
                _tradesMap[index] = tradesMap[i];
                index++;
            }
        }
        return _tradesMap;
    }

    // @dev function for look by user
    function lookAllTrades(address _userAddress)
        public
        view
        returns (TradeData[] memory)
    {
        require(_userAddress != address(0), "Invalid address");
        // get the total of tradesMap for the user address
        uint256 total = 0;
        for (uint256 i = 1; i <= tradeCount; i++) {
            if (tradesMap[i].seller == _userAddress) {
                total++;
            }
        }

        if (total == 0) {
            return new TradeData[](0);
        }

        TradeData[] memory _tradesMap = new TradeData[](total);
        uint256 index = 0;
        for (uint256 i = 1; i <= tradeCount; i++) {
            if (tradesMap[i].seller == _userAddress) {
                _tradesMap[index] = tradesMap[i];
                index++;
            }
        }

        return _tradesMap;
    }

    // @dev function that returns the total  of tradesMap of a user
    function totalTradesByUser(address _userAddress)
        public
        view
        returns (uint256)
    {
        uint256 total = 0;
        for (uint256 i = 1; i <= tradeCount; i++) {
            if (tradesMap[i].seller == _userAddress) {
                total++;
            }
        }
        return total;
    }

    //@dev function that checks if the user exists
    function userExists(address _userAddress) public view returns (bool) {
        if (bytes(usersMap[_userAddress].email).length > 0) {
            return true;
        } else {
            return false;
        }
    }

    //@dev function for look usersMap in the market
    function lookUsers(address _userAddress)
        public
        view
        returns (userData memory)
    {
        // validate that user exists
        require(
            bytes(usersMap[_userAddress].email).length > 0,
            "User does not exist"
        );
        userData storage _user = usersMap[_userAddress];
        return _user;
    }

    //@dev function for buy one trade
    function buyTrade(uint256 _itemId) public payable nonReentrant {
        require(msg.value == tradesMap[_itemId].price, "Invalid value");
        require(tradesMap[_itemId].isSold == false, "Invalid trade, item sold");
        require(tradesMap[_itemId].seller != address(0), "Invalid seller");
        require(tradesMap[_itemId].seller != msg.sender, "Invalid seller");
        tradesMap[_itemId].buyer = msg.sender;
        tradesMap[_itemId].isSold = true;
        emit TradeCompleted(
            _itemId,
            tradesMap[_itemId].buyer,
            tradesMap[_itemId].seller,
            tradesMap[_itemId].price
        );
    }

    event TradeCompleted(
        uint256 _itemId,
        address _buyer,
        address _seller,
        uint256 _price
    );

    function staking(uint256 _itemId) public payable nonReentrant {
        require(tradesMap[_itemId].isSold == true, "Invalid trade");
        require(
            tradesMap[_itemId].staking == false,
            "Invalid trade, item sold"
        );
        require(tradesMap[_itemId].seller == msg.sender, "Invalid seller");
        payable(tradesMap[_itemId].seller).transfer(tradesMap[_itemId].price);
        tradesMap[_itemId].staking = true;
        delete tradesMap[_itemId];
        tradeCount--;
        emit StakingComlpeted(_itemId);
    }

    event StakingComlpeted(uint256 _itemId);

    //@dev function for cancel one trade
    function cancelTrade(uint256 _itemId) public nonReentrant {
        require(msg.sender != address(0), "Invalid address");
        require(tradesMap[_itemId].isSold == false, "Invalid trade, item sold");
        require(tradesMap[_itemId].seller != address(0), "Invalid address");
        require(tradesMap[_itemId].seller == msg.sender, "Invalid seller");

        if (
            tradesMap[_itemId].isSold == true &&
            tradesMap[_itemId].staking == false
        ) {
            payable(tradesMap[_itemId].buyer).transfer(
                tradesMap[_itemId].price
            );
        }

        delete tradesMap[_itemId];
        tradeCount--;
    }
}