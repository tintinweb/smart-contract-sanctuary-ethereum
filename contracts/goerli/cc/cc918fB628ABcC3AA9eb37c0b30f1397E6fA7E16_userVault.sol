/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

pragma solidity ^0.8.9;

contract userVault {
    constructor() {}

    struct CreatorToken {
        string token_network;
        string token_name;
    }
    uint256 creatoreTokenId;
    struct userData {
        address creator;
        address next_of_kin;
        string creator_name;
        string next_of_kin_name;
        string next_of_kin_email;
        uint256 next_of_kin_phone;
        uint256 next_of_kin_otp;
        string _token_network;
        string _token_name;
    }

    mapping(address => mapping(uint256 => CreatorToken)) public creatorToken;
    mapping(address => uint256) public currentCreatorTokenIndex;

    mapping(address => userData) public all_users;
    // mapping(address => CreatorToken) myToken;

    address[] public userAccts;

    function storeNextOfKinInfo(
        string calldata creator_name,
        string calldata next_of_kin_name,
        string calldata next_of_kin_email,
        uint _next_of_kin_phone,
        uint _next_of_kin_otp,
        string memory _token_network,
        string memory _token_name
    ) public {
        all_users[msg.sender] = userData(
            msg.sender,
            address(0),
            creator_name,
            next_of_kin_name,
            next_of_kin_email,
            _next_of_kin_phone,
            _next_of_kin_otp,
            _token_network,
            _token_name
        );

        addCreatorTokens(_token_name, _token_network);
    }

    function addCreatorTokens(
        string memory _token_name,
        string memory _token_network
    ) private {
        creatorToken[msg.sender][
            currentCreatorTokenIndex[msg.sender]
        ] = CreatorToken(_token_name, _token_network);
    }

    function getCreatorTokens(uint startIndex, uint256 endIndex)
        public
        view
        returns (
            userData memory _userData,
            CreatorToken[] memory _creatorTokens
        )
    {
        _userData = all_users[msg.sender];
        uint256 length = endIndex - startIndex;
        _creatorTokens = new CreatorToken[](length);
        for (uint i = 0; i < currentCreatorTokenIndex[msg.sender]; i++) {
            _creatorTokens[i] = creatorToken[msg.sender][i];
        }
    }
}