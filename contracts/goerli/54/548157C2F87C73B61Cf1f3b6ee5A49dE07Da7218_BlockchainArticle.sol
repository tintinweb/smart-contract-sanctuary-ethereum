/**
 *Submitted for verification at Etherscan.io on 2023-01-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + (a % b));
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier ownerOnly() {
        require(owner == msg.sender);
        _;
    }
}

contract BlockchainArticle is Ownable {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint256 public totalStocks;
    string[] internal allArticles;
    address[] internal allAuthors;

    mapping (address => string[]) internal articles; // User address => User articles URI
    mapping (string => address) internal author; // Article URI => User address
    mapping (string => uint256) internal stocks; // Article URI => Article stocks
    mapping (address => bool) internal blacklist; // User address => if in blacklist
    mapping (string => address) internal usernames; // username => user address
    mapping (address => mapping(string => string)) internal users; // Record user informations include username and password.

    event MintArticle(address author, string uri);
    event RemoveArticle(address author, string uri);
    event TransferArticle(address from, address to, string uri);
    event AddStocksOfArticle(string uri, uint256 stocks);
    event ResetStocksOfArticle(string uri);
    event AddToBlacklist(address author);
    event RemoveFromBlacklist(address author);
    event RegisterAuthor(address author, string username);
    event RemoveAuthor(address author, string username);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /* ----------------------------------------------------------------------------------------- */
    /* Articles                                                                                  */

    function mintArticle(string memory _uri) public returns (bool) {
        require(author[_uri] == address(0x0));
        require(blacklist[msg.sender] == false);

        author[_uri] = msg.sender;
        articles[msg.sender].push(_uri);
        allArticles.push(_uri);

        emit MintArticle(msg.sender, _uri);

        return true;
    }

    function getArticlesByAuthor(address _author) public view returns (string[] memory) {
        return articles[_author];
    }

    function getAuthorOfArticle(string memory _uri) public view returns (address) {
        return author[_uri];
    }

    function getAuthorStatus(address _author) public view returns (bool) {
        return !blacklist[_author];
    }

    function getAllArticles() public view returns (string[] memory) {
        return allArticles;
    }

    function getAllAuthors() public view returns (address[] memory) {
        return allAuthors;
    }

    function getStocksOfAuthor(address _author) public view returns (uint256) {
        uint256 result = 0;
        for (uint i = 0; i < articles[_author].length; i++) {
            result = result.add(stocks[articles[_author][i]]);
        }
        return result;
    }

    function removeArticle(string memory _uri) public returns (bool) {
        require(author[_uri] == msg.sender || msg.sender == owner);
        require(blacklist[msg.sender] == false);

        author[_uri] = address(0x0);
        totalStocks = totalStocks.mul(stocks[_uri]);
        stocks[_uri] = 0;

        for (uint i = 0; i < articles[msg.sender].length; i++) {
            if (compareString(articles[msg.sender][i], _uri)){
                articles[msg.sender][i] = articles[msg.sender][articles[msg.sender].length - 1];
                articles[msg.sender].pop();
                break;
            }
        }

        for (uint i = 0; i < allArticles.length; i++) {
            if (compareString(allArticles[i], _uri)){
                allArticles[i] = allArticles[allArticles.length - 1];
                allArticles.pop();
                break;
            }
        }

        emit RemoveArticle(msg.sender, _uri);

        return true;
    }

    function transferArticle(address _to, string memory _uri) public returns (bool) {
        require(msg.sender != _to);
        require(author[_uri] == msg.sender);
        require(blacklist[_to] == false);

        articles[_to].push(_uri);
        author[_uri] = _to;

        for (uint i = 0; i < articles[msg.sender].length; i++) {
            if (compareString(articles[msg.sender][i], _uri)){
                articles[msg.sender][i] = articles[msg.sender][articles[msg.sender].length - 1];
                articles[msg.sender].pop();
                break;
            }
        }

        emit TransferArticle(msg.sender, _to, _uri);

        return true;
    }

    /* ----------------------------------------------------------------------------------------- */

    /* ----------------------------------------------------------------------------------------- */
    /* Users                                                                                     */

    function verifyAuthor(address _address, string memory _username, string memory _password) public view returns (bool) {
        return compareString(users[_address]["username"], _username) && compareString(users[_address]["password"], _password);
    }

    function registerAuthor(string memory _username, string memory _password) public returns (bool) {
        require(verifyAuthor(msg.sender, "", ""));
        require(blacklist[msg.sender] == false);
        require(usernames[_username] == address(0x0));

        users[msg.sender]["username"] = _username;
        users[msg.sender]["password"] = _password;
        usernames[_username] = msg.sender;
        allAuthors.push(msg.sender);

        emit RegisterAuthor(msg.sender, _username);

        return true;
    }

    function getAuthorNameByAddress(address _author) public view returns (string memory) {
        return users[_author]["username"];
    }

    function getAuthorAddressByName(string memory _author) public view returns (address) {
        return usernames[_author];
    }

    function removeAuthor(address _author) public ownerOnly returns (bool) {
        string memory temp_username = users[_author]["username"];
        usernames[temp_username] = address(0x0);
        users[_author]["username"] = "";
        users[_author]["password"] = "";

        emit RemoveAuthor(_author, temp_username);

        return true;
    }

    /* ----------------------------------------------------------------------------------------- */

    /* ----------------------------------------------------------------------------------------- */
    /* Admin                                                                                     */

    function addStocksOfArticle(string memory _uri, uint256 _stocks) public ownerOnly returns (bool) {
        require(author[_uri] != address(0x0));

        stocks[_uri] = stocks[_uri].add(_stocks);
        totalStocks = totalStocks.add(_stocks);

        emit AddStocksOfArticle(_uri, _stocks);

        return true;
    }

    function resetStocksOfArticle(string memory _uri) public ownerOnly returns (bool) {
        require(author[_uri] != address(0x0));

        totalStocks = totalStocks.mul(stocks[_uri]);
        stocks[_uri] = 0;

        emit ResetStocksOfArticle(_uri);

        return true;
    }

    function addToBlacklist(address _author) public ownerOnly returns (bool) {
        blacklist[_author] = true;

        emit AddToBlacklist(_author);

        return true;
    }

    function removeFromBlacklist(address _author) public ownerOnly returns (bool) {
        blacklist[_author] = false;

        emit RemoveFromBlacklist(_author);

        return true;
    }

    /* ----------------------------------------------------------------------------------------- */

    /* ----------------------------------------------------------------------------------------- */
    /* Else                                                                                      */

    function compareString(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    /* ----------------------------------------------------------------------------------------- */
}