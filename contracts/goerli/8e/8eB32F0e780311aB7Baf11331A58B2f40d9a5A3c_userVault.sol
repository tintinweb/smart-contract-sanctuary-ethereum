/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

contract userVault {
    constructor() {}

    struct CreatorToken {
        string token_network;
        string token_name;
    }

    struct userData {
        address creator;
        address next_of_kin;
        string creator_name;
        string next_of_kin_name;
        string next_of_kin_email;
        uint next_of_kin_phone;
        uint next_of_kin_otp;
    }

    mapping(address => mapping(uint => CreatorToken)) creatorToken;
    mapping(address => uint) public currentCreatorTokenIndex;

    mapping(address => userData) all_users;
    // mapping(address => CreatorToken) myToken;

    address[] public userAccts;

    function storeNextOfKinInfo(
        string calldata creator_name,
        string calldata next_of_kin_name,
        string calldata next_of_kin_email,
        uint _next_of_kin_phone,
        uint _next_of_kin_otp,
        CreatorToken[] calldata _creatorTokens
    ) public {
        all_users[msg.sender] = userData(
            msg.sender,
            address(0),
            creator_name,
            next_of_kin_name,
            next_of_kin_email,
            _next_of_kin_phone,
            _next_of_kin_otp
        );

        addCreatorTokens(_creatorTokens);
    }

    function addCreatorTokens(CreatorToken[] calldata _creatorTokens) private {
        for (uint i = 0; i < _creatorTokens.length; i++) {
            creatorToken[msg.sender][
                currentCreatorTokenIndex[msg.sender]
            ] = _creatorTokens[i];
            currentCreatorTokenIndex[msg.sender]++;
        }
    }

    function getCreatorTokens(
        address user,
        uint startIndex,
        uint256 endIndex
    )
        public
        view
        returns (
            userData memory _userData,
            CreatorToken[] memory _creatorTokens
        )
    {
        _userData = all_users[user];
        uint256 length = endIndex - startIndex;
        _creatorTokens = new CreatorToken[](length);
        for (uint i = startIndex; i < endIndex; i++) {
            _creatorTokens[i] = creatorToken[msg.sender][i];
        }
    }
}