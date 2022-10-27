//  SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./ERC721.sol";

contract Extension is Ownable {
    address public condorNFTAddress =
        0xa9EA970A3DDB27ad3Fb791573C0a4b0F82e93256;
    address public tier1NFTAddress = 0xa9EA970A3DDB27ad3Fb791573C0a4b0F82e93256;
    address public tier2NFTAddress = 0xa9EA970A3DDB27ad3Fb791573C0a4b0F82e93256;
    address public tier3NFTAddress = 0xa9EA970A3DDB27ad3Fb791573C0a4b0F82e93256;
    address public tier4NFTAddress = 0xa9EA970A3DDB27ad3Fb791573C0a4b0F82e93256;

    uint256 private condorNFTNumber = 0;
    uint256 private tier1NFTNumber = 0;
    uint256 private tier2NFTNumber = 0;
    uint256 private tier3NFTNumber = 0;
    uint256 private tier4NFTNumber = 0;

    uint8 private coefficientForCondor = 100;
    uint8 private coefficientForTier1 = 50;
    uint8 private coefficientForTier2 = 20;
    uint8 private coefficientForTier3 = 10;
    uint8 private coefficientForTier4 = 5;

    uint256 scondorAmountFor1USD = 0;

    mapping(address => bool) private isSetAmount;
    mapping(address => bool) private isSetMultiplier;

    mapping(address => uint256) private multiplier;
    mapping(address => uint256) private buyAmount;

    uint256 rewardAmount = 0;
    uint256 initialMultiplier = 10;

    address public signerAddress; // get from backend private key

    constructor() {}

    /* We can set the NFT collection address */

    function setCondorNFTAddress(address newCondorNFTAddress)
        external
        onlyOwner
    {
        condorNFTAddress = newCondorNFTAddress;
    }

    function setTier1NFTAddress(address newTier1NFTAddress) external onlyOwner {
        tier1NFTAddress = newTier1NFTAddress;
    }

    function setTier2NFTAddress(address newTier2NFTAddress) external onlyOwner {
        tier2NFTAddress = newTier2NFTAddress;
    }

    function setTier3NFTAddress(address newTier3NFTAddress) external onlyOwner {
        tier3NFTAddress = newTier3NFTAddress;
    }

    function setTier4NFTAddress(address newTier4NFTAddress) external onlyOwner {
        tier4NFTAddress = newTier4NFTAddress;
    }

    function setInitialMultiplier(uint256 multiplier) external onlyOwner {
        initialMultiplier = multiplier;
    }

    function getInitialMultiplier() public view returns (uint256) {
        return initialMultiplier;
    }

    /* We can get the NFT Balance for each NFT collection address */

    function getCondorNFTBalance() public {
        condorNFTNumber = ERC721(condorNFTAddress).balanceOf(msg.sender);
    }

    function getTier1NFTBalance() public {
        tier1NFTNumber = ERC721(tier1NFTAddress).balanceOf(msg.sender);
    }

    function getTier2NFTBalance() public {
        tier2NFTNumber = ERC721(tier2NFTAddress).balanceOf(msg.sender);
    }

    function getTier3NFTBalance() public {
        tier3NFTNumber = ERC721(tier3NFTAddress).balanceOf(msg.sender);
    }

    function getTier4NFTBalance() public {
        tier4NFTNumber = ERC721(tier4NFTAddress).balanceOf(msg.sender);
    }

    /* We can update the coefficient for each types of NFT holders */

    function setCondorNFTCoefficient(uint8 newCondorNFTCoefficient)
        external
        onlyOwner
    {
        coefficientForCondor = newCondorNFTCoefficient;
    }

    function setTier1NFTCoefficient(uint8 newTier1NFTCoefficient)
        external
        onlyOwner
    {
        coefficientForTier1 = newTier1NFTCoefficient;
    }

    function setTier2NFTCoefficient(uint8 newTier2NFTCoefficient)
        external
        onlyOwner
    {
        coefficientForTier2 = newTier2NFTCoefficient;
    }

    function setTier3NFTCoefficient(uint8 newTier3NFTCoefficient)
        external
        onlyOwner
    {
        coefficientForTier3 = newTier3NFTCoefficient;
    }

    function setTier4NFTCoefficient(uint8 newTier4NFTCoefficient)
        external
        onlyOwner
    {
        coefficientForTier4 = newTier4NFTCoefficient;
    }

    /* Backend calls this function  */

    function setMultiplier(address rewardAddress) public {
        isSetMultiplier[rewardAddress] = true;
        multiplier[rewardAddress] =
            (condorNFTNumber *
                coefficientForCondor +
                tier1NFTNumber *
                coefficientForTier1 +
                tier2NFTNumber *
                coefficientForTier2 +
                tier3NFTNumber *
                coefficientForTier3 +
                tier4NFTNumber *
                coefficientForTier4) *
            getInitialMultiplier();
    }

    /* This function also be called by backend 
    For this function user must be verified */

    function setBuyAmount(
        address rewardAddress,
        uint256 _userBuyAmount,
        bytes memory _signature
    ) public returns (bool) {
        require(
            verify(rewardAddress, _userBuyAmount, _signature),
            "Signature is failed"
        );
        buyAmount[rewardAddress] = _userBuyAmount;
        isSetAmount[rewardAddress] = true;

        return true;
    }

    /* This function gets muliplier coefficient */

    function getMultiplier(address rewardAddress)
        public
        view
        returns (uint256)
    {
        require(
            isSetMultiplier[rewardAddress],
            "Set Multiplier function must be called"
        );
        return multiplier[rewardAddress];
    }

    /* This function gets buyAmount that was buyed by user and displayed by USD */

    function getBuyAmount(address rewardAddress) public view returns (uint256) {
        require(
            isSetAmount[rewardAddress],
            "Set Amount function must be called"
        );
        return buyAmount[rewardAddress];
    }

    /* This function sets scondor amount for $1 */

    function setScondorAmountFor1USD(address rewardAddress) public {
        require(
            isSetAmount[rewardAddress],
            "Set Amount function must be called"
        );
        require(
            isSetMultiplier[rewardAddress],
            "Set Multiplier function must be called"
        );
        require(buyAmount[rewardAddress] == 0, "Buyamount can't be zero");
        scondorAmountFor1USD =
            multiplier[rewardAddress] /
            buyAmount[rewardAddress];
    }

    /* This function gets scondor amount for $1 */

    function getScondorAmountFor1USD(address rewardAddress)
        public
        view
        returns (uint256)
    {
        require(
            isSetAmount[rewardAddress],
            "Set Amount function must be called"
        );
        require(
            isSetMultiplier[rewardAddress],
            "Set Multiplier function must be called"
        );
        return scondorAmountFor1USD;
    }

    function getMessageHash(
        address _to,
        uint256 _amount,
        string memory _message,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _message, _nonce));
    }

    function calculateRewardAmount(address rewardAddress) external {
        require(isSetAmount[rewardAddress], "Please signature and set amount");
        rewardAmount = buyAmount[rewardAddress] * multiplier[rewardAddress];
    }

    function getMessageHash(address _buyer, uint256 _amount)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_buyer, _amount));
    }

    function verify(
        address _buyer,
        uint256 _amount,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHash(_buyer, _amount);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == signerAddress;
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}