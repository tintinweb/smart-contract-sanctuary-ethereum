pragma solidity ^0.5.0;

import './GenArt721Minter_DoodleLabs_MultiMinter.sol';
import './Strings.sol';
import './MerkleProof.sol';

interface IGenArt721Minter_DoodleLabs_Config {
    function getPurchaseManyLimit(uint256 projectId) external view returns (uint256 limit);

    function getState(uint256 projectId) external view returns (uint256 _state);

    function setStateFamilyCollectors(uint256 projectId) external;

    function setStateRedemption(uint256 projectId) external;

    function setStatePublic(uint256 projectId) external;
}

interface IGenArt721Minter_DoodleLabs_WhiteList {
    function getMerkleRoot(uint256 projectId) external view returns (bytes32 merkleRoot);

    function getWhitelisted(uint256 projectId, address user) external view returns (uint256 amount);

    function addWhitelist(
        uint256 projectId,
        address[] calldata users,
        uint256[] calldata amounts
    ) external;

    function increaseAmount(
        uint256 projectId,
        address to,
        uint256 quantity
    ) external;
}

contract GenArt721Minter_DoodleLabs_Custom_Sale is GenArt721Minter_DoodleLabs_MultiMinter {
    using SafeMath for uint256;

    event Redeem(uint256 projectId);

    // Must match what is on the GenArtMinterV2_State contract
    enum SaleState {
        FAMILY_COLLECTORS,
        REDEMPTION,
        PUBLIC
    }

    IGenArt721Minter_DoodleLabs_WhiteList public activeWhitelist;
    IGenArt721Minter_DoodleLabs_Config public minterState;

    modifier onlyWhitelisted() {
        require(genArtCoreContract.isWhitelisted(msg.sender), 'can only be set by admin');
        _;
    }

    modifier notRedemptionState(uint256 projectId) {
        require(
            uint256(minterState.getState(projectId)) != uint256(SaleState.REDEMPTION),
            'can not purchase in redemption phase'
        );
        _;
    }

    modifier onlyRedemptionState(uint256 projectId) {
        require(
            uint256(minterState.getState(projectId)) == uint256(SaleState.REDEMPTION),
            'not in redemption phase'
        );
        _;
    }

    constructor(address _genArtCore, address _minterStateAddress)
        public
        GenArt721Minter_DoodleLabs_MultiMinter(_genArtCore)
    {
        minterState = IGenArt721Minter_DoodleLabs_Config(_minterStateAddress);
    }

    function getMerkleRoot(uint256 projectId) public view returns (bytes32 merkleRoot) {
        require(address(activeWhitelist) != address(0), 'Active whitelist not set');
        return activeWhitelist.getMerkleRoot(projectId);
    }

    function getWhitelisted(uint256 projectId, address user)
        external
        view
        returns (uint256 amount)
    {
        require(address(activeWhitelist) != address(0), 'Active whitelist not set');
        return activeWhitelist.getWhitelisted(projectId, user);
    }

    function setActiveWhitelist(address whitelist) public onlyWhitelisted {
        activeWhitelist = IGenArt721Minter_DoodleLabs_WhiteList(whitelist);
    }

    function purchase(uint256 projectId, uint256 quantity)
        public
        payable
        notRedemptionState(projectId)
        returns (uint256[] memory _tokenIds)
    {
        return purchaseTo(msg.sender, projectId, quantity);
    }

    function purchaseTo(
        address to,
        uint256 projectId,
        uint256 quantity
    ) public payable notRedemptionState(projectId) returns (uint256[] memory _tokenIds) {
        require(
            quantity <= minterState.getPurchaseManyLimit(projectId),
            'Max purchase many limit reached'
        );
        if (
            uint256(minterState.getState(projectId)) == uint256(SaleState.FAMILY_COLLECTORS) &&
            msg.value > 0
        ) {
            require(false, 'ETH not accepted at this time');
        }
        return _purchaseManyTo(to, projectId, quantity);
    }

    function redeem(
        uint256 projectId,
        uint256 quantity,
        uint256 allottedAmount,
        bytes32[] memory proof
    ) public payable onlyRedemptionState(projectId) returns (uint256[] memory _tokenIds) {
        return redeemTo(msg.sender, projectId, quantity, allottedAmount, proof);
    }

    function redeemTo(
        address to,
        uint256 projectId,
        uint256 quantity,
        uint256 allottedAmount,
        bytes32[] memory proof
    ) public payable onlyRedemptionState(projectId) returns (uint256[] memory _tokenIds) {
        require(address(activeWhitelist) != address(0), 'Active whitelist not set');
        require(
            activeWhitelist.getWhitelisted(projectId, to).add(quantity) <= allottedAmount,
            'Address has already claimed'
        );

        string memory key = _addressToString(to);
        key = _appendStrings(key, Strings.toString(allottedAmount), Strings.toString(projectId));

        bytes32 leaf = keccak256(abi.encodePacked(key));
        require(MerkleProof.verify(proof, getMerkleRoot(projectId), leaf), 'Invalid proof');

        uint256[] memory createdTokens = _purchaseManyTo(to, projectId, quantity);

        activeWhitelist.increaseAmount(projectId, to, quantity);

        emit Redeem(projectId);
        return createdTokens;
    }

    function _appendStrings(
        string memory a,
        string memory b,
        string memory c
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, '::', b, '::', c));
    }

    function _addressToString(address addr) private pure returns (string memory) {
        // From: https://www.reddit.com/r/ethdev/comments/qga46a/i_created_a_function_to_convert_address_to_string/
        // Cast address to byte array
        bytes memory addressBytes = abi.encodePacked(addr);

        // Byte array for the new string
        bytes memory stringBytes = new bytes(42);

        // Assign first two bytes to '0x'
        stringBytes[0] = '0';
        stringBytes[1] = 'x';

        // Iterate over every byte in the array
        // Each byte contains two hex digits that gets individually converted
        // into their ASCII representation and added to the string
        for (uint256 i = 0; i < 20; i++) {
            // Convert hex to decimal values
            uint8 leftValue = uint8(addressBytes[i]) / 16;
            uint8 rightValue = uint8(addressBytes[i]) - 16 * leftValue;

            // Convert decimals to ASCII values
            bytes1 leftChar = leftValue < 10 ? bytes1(leftValue + 48) : bytes1(leftValue + 87);
            bytes1 rightChar = rightValue < 10 ? bytes1(rightValue + 48) : bytes1(rightValue + 87);

            // Add ASCII values to the string byte array
            stringBytes[2 * i + 3] = rightChar;
            stringBytes[2 * i + 2] = leftChar;

            // console.log(string(stringBytes));
        }

        // Cast byte array to string and return
        return string(stringBytes);
    }
}