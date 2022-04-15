/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

/**
 * @title PA1D (CXIP)
 * @author CXIP-Labs
 * @notice A smart contract for providing royalty info, collecting royalties, and distributing it to configured payout wallets.
 * @dev This smart contract is not intended to be used directly. Apply it to any of your ERC721 or ERC1155 smart contracts through a delegatecall fallback.
 */
contract PA1D {
    /**
     * @notice Event emitted when setting/updating royalty info/fees. This is used by Rarible V1.
     * @dev Emits event in order to comply with Rarible V1 royalty spec.
     * @param tokenId Specific token id for which royalty info is being set, set as 0 for all tokens inside of the smart contract.
     * @param recipients Address array of wallets that will receive tha royalties.
     * @param bps Uint256 array of base points(percentages) that each wallet(specified in recipients) will receive from the royalty payouts. Make sure that all the base points add up to a total of 10000.
     */
    event SecondarySaleFees(uint256 tokenId, address[] recipients, uint256[] bps);

    /**
     * @dev Use this modifier to lock public functions that should not be accesible to non-owners.
     */
    modifier onlyOwner() {
        require(isOwner(), "PA1D: caller not an owner");
        _;
    }

    /**
     * @notice Constructor is empty and not utilised.
     * @dev Since the smart contract is being used inside of a fallback context, the constructor function is not being used.
     */
    constructor() {}

    /**
     * @notice Initialise the smart contract on source smart contract deployment/initialisation.
     * @dev Use the init function once, when deploying or initialising your overlying smart contract.
     * @dev Take great care to not expose this function to your other public functions.
     * @param tokenId Specify a particular token id only if using the init function for a special case. Otherwise leave empty(0).
     * @param receiver The address for the default receiver of all royalty payouts. Recommended to use the overlying smart contract address. This will allow the PA1D smart contract to handle all royalty settings, receipt, and distribution.
     * @param bp The default base points(percentage) for royalty payouts.
     */
    function init(
        uint256 tokenId,
        address payable receiver,
        uint256 bp
    ) public onlyOwner {}

    /**
     * @dev Get the top-level CXIP Registry smart contract. Function must always be internal to prevent miss-use/abuse through bad programming practices.
     * @return The address of the top-level CXIP Registry smart contract.
     */
    function getRegistry() internal pure returns (ICxipRegistry) {
        return ICxipRegistry(0xC267d41f81308D7773ecB3BDd863a902ACC01Ade);
    }

    /**
     * @notice Check if the underlying identity has sender as registered wallet.
     * @dev Check the overlying smart contract's identity for wallet registration.
     * @param sender Address which should be checked against the identity.
     * @return Returns true if the sender is a valid wallet of the identity.
     */
    function isIdentityWallet(address sender) internal view returns (bool) {
        return isIdentityWallet(ICxipERC(address(this)).getIdentity(), sender);
    }

    /**
     * @notice Check if a specific identity has sender as registered wallet.
     * @dev Don't use this function directly unless you know what you're doing.
     * @param identity Address of the identity smart contract.
     * @param sender Address which should be checked against the identity.
     * @return Returns true if the sender is a valid wallet of the identity.
     */
    function isIdentityWallet(address identity, address sender) internal view returns (bool) {
        if (Address.isZero(identity)) {
            return false;
        }
        return ICxipIdentity(identity).isWalletRegistered(sender);
    }

    /**
     * @notice Check if message sender is a legitimate owner of the smart contract
     * @dev We check owner, admin, and identity for a more comprehensive coverage.
     * @return Returns true is message sender is an owner.
     */
    function isOwner() internal view returns (bool) {
        ICxipERC erc = ICxipERC(address(this));
        return (msg.sender == erc.owner() ||
            msg.sender == erc.admin() ||
            isIdentityWallet(erc.getIdentity(), msg.sender));
    }

    /**
     * @dev Gets the default royalty payment receiver address from storage slot.
     * @return receiver Wallet or smart contract that will receive the initial royalty payouts.
     */
    function _getDefaultReceiver() internal view returns (address payable receiver) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.PA1D.defaultReceiver')) - 1);
        assembly {
            receiver := sload(
                /* slot */
                0xaee4e97c19ce50ea5345ba9751676d533a3a7b99c3568901208f92f9eea6a7f2
            )
        }
    }

    /**
     * @dev Sets the default royalty payment receiver address to storage slot.
     * @param receiver Wallet or smart contract that will receive the initial royalty payouts.
     */
    function _setDefaultReceiver(address receiver) internal {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.PA1D.defaultReceiver')) - 1);
        assembly {
            sstore(
                /* slot */
                0xaee4e97c19ce50ea5345ba9751676d533a3a7b99c3568901208f92f9eea6a7f2,
                receiver
            )
        }
    }

    /**
     * @dev Gets the default royalty base points(percentage) from storage slot.
     * @return bp Royalty base points(percentage) for royalty payouts.
     */
    function _getDefaultBp() internal view returns (uint256 bp) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.PA1D.defaultBp')) - 1);
        assembly {
            bp := sload(
                /* slot */
                0xfd198c3b406b2320ea9f4a413c7a69a7592dbfc4175b8c252fec24223e68b720
            )
        }
    }

    /**
     * @dev Sets the default royalty base points(percentage) to storage slot.
     * @param bp Uint256 of royalty percentage, provided in base points format.
     */
    function _setDefaultBp(uint256 bp) internal {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.PA1D.defaultBp')) - 1);
        assembly {
            sstore(
                /* slot */
                0xfd198c3b406b2320ea9f4a413c7a69a7592dbfc4175b8c252fec24223e68b720,
                bp
            )
        }
    }

    /**
     * @dev Gets the royalty payment receiver address, for a particular token id, from storage slot.
     * @return receiver Wallet or smart contract that will receive the royalty payouts for a particular token id.
     */
    function _getReceiver(uint256 tokenId) internal view returns (address payable receiver) {
        bytes32 slot = bytes32(
            uint256(keccak256(abi.encodePacked("eip1967.PA1D.receiver", tokenId))) - 1
        );
        assembly {
            receiver := sload(slot)
        }
    }

    /**
     * @dev Sets the royalty payment receiver address, for a particular token id, to storage slot.
     * @param tokenId Uint256 of the token id to set the receiver for.
     * @param receiver Wallet or smart contract that will receive the royalty payouts for a particular token id.
     */
    function _setReceiver(uint256 tokenId, address receiver) internal {
        bytes32 slot = bytes32(
            uint256(keccak256(abi.encodePacked("eip1967.PA1D.receiver", tokenId))) - 1
        );
        assembly {
            sstore(slot, receiver)
        }
    }

    /**
     * @dev Gets the royalty base points(percentage), for a particular token id, from storage slot.
     * @return bp Royalty base points(percentage) for the royalty payouts of a specific token id.
     */
    function _getBp(uint256 tokenId) internal view returns (uint256 bp) {
        bytes32 slot = bytes32(
            uint256(keccak256(abi.encodePacked("eip1967.PA1D.bp", tokenId))) - 1
        );
        assembly {
            bp := sload(slot)
        }
    }

    /**
     * @dev Sets the royalty base points(percentage), for a particular token id, to storage slot.
     * @param tokenId Uint256 of the token id to set the base points for.
     * @param bp Uint256 of royalty percentage, provided in base points format, for a particular token id.
     */
    function _setBp(uint256 tokenId, uint256 bp) internal {
        bytes32 slot = bytes32(
            uint256(keccak256(abi.encodePacked("eip1967.PA1D.bp", tokenId))) - 1
        );
        assembly {
            sstore(slot, bp)
        }
    }

    function _getPayoutAddresses() internal view returns (address payable[] memory addresses) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.PA1D.payout.addresses')) - 1);
        bytes32 slot = 0xda9d0b1bc91e594968e30b896be60318d483303fc3ba08af8ac989d483bdd7ca;
        uint256 length;
        assembly {
            length := sload(slot)
        }
        addresses = new address payable[](length);
        address payable value;
        for (uint256 i = 0; i < length; i++) {
            slot = keccak256(abi.encodePacked(i, slot));
            assembly {
                value := sload(slot)
            }
            addresses[i] = value;
        }
    }

    function _setPayoutAddresses(address payable[] memory addresses) internal {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.PA1D.payout.addresses')) - 1);
        bytes32 slot = 0xda9d0b1bc91e594968e30b896be60318d483303fc3ba08af8ac989d483bdd7ca;
        uint256 length = addresses.length;
        assembly {
            sstore(slot, length)
        }
        address payable value;
        for (uint256 i = 0; i < length; i++) {
            slot = keccak256(abi.encodePacked(i, slot));
            value = addresses[i];
            assembly {
                sstore(slot, value)
            }
        }
    }

    function _getPayoutBps() internal view returns (uint256[] memory bps) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.PA1D.payout.bps')) - 1);
        bytes32 slot = 0x7862b872ab9e3483d8176282b22f4ac86ad99c9035b3f794a541d84a66004fa2;
        uint256 length;
        assembly {
            length := sload(slot)
        }
        bps = new uint256[](length);
        uint256 value;
        for (uint256 i = 0; i < length; i++) {
            slot = keccak256(abi.encodePacked(i, slot));
            assembly {
                value := sload(slot)
            }
            bps[i] = value;
        }
    }

    function _setPayoutBps(uint256[] memory bps) internal {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.PA1D.payout.bps')) - 1);
        bytes32 slot = 0x7862b872ab9e3483d8176282b22f4ac86ad99c9035b3f794a541d84a66004fa2;
        uint256 length = bps.length;
        assembly {
            sstore(slot, length)
        }
        uint256 value;
        for (uint256 i = 0; i < length; i++) {
            slot = keccak256(abi.encodePacked(i, slot));
            value = bps[i];
            assembly {
                sstore(slot, value)
            }
        }
    }

    function _getTokenAddress(string memory tokenName)
        internal
        view
        returns (address tokenAddress)
    {
        bytes32 slot = bytes32(
            uint256(keccak256(abi.encodePacked("eip1967.PA1D.tokenAddress", tokenName))) - 1
        );
        assembly {
            tokenAddress := sload(slot)
        }
    }

    function _setTokenAddress(string memory tokenName, address tokenAddress) internal {
        bytes32 slot = bytes32(
            uint256(keccak256(abi.encodePacked("eip1967.PA1D.tokenAddress", tokenName))) - 1
        );
        assembly {
            sstore(slot, tokenAddress)
        }
    }

    /**
     * @dev Internal function that transfers ETH to all payout recipients.
     */
    function _payoutEth() internal {
        address payable[] memory addresses = _getPayoutAddresses();
        uint256[] memory bps = _getPayoutBps();
        uint256 length = addresses.length;
        // accommodating the 2300 gas stipend
        // adding 1x for each item in array to accomodate rounding errors
        uint256 gasCost = (23300 * length) + length;
        uint256 balance = address(this).balance;
        require(balance - gasCost > 10000, "PA1D: Not enough ETH to transfer");
        balance = balance - gasCost;
        uint256 sending;
        for (uint256 i = 0; i < length; i++) {
            sending = ((bps[i] * balance) / 10000);
            addresses[i].transfer(sending);
        }
    }

    /**
     * @dev Internal function that transfers tokens to all payout recipients.
     * @param tokenAddress Smart contract address of ERC20 token.
     */
    function _payoutToken(address tokenAddress) internal {
        address payable[] memory addresses = _getPayoutAddresses();
        uint256[] memory bps = _getPayoutBps();
        uint256 length = addresses.length;
        IERC20 erc20 = IERC20(tokenAddress);
        uint256 balance = erc20.balanceOf(address(this));
        require(balance > 10000, "PA1D: Not enough tokens to transfer");
        uint256 sending;
        //uint256 sent;
        for (uint256 i = 0; i < length; i++) {
            sending = ((bps[i] * balance) / 10000);
            require(erc20.transfer(addresses[i], sending), "PA1D: Couldn't transfer token");
        }
    }

    /**
     * @dev Internal function that transfers multiple tokens to all payout recipients.
     * @dev Try to use _payoutToken and handle each token individually.
     * @param tokenAddresses Array of smart contract addresses of ERC20 tokens.
     */
    function _payoutTokens(address[] memory tokenAddresses) internal {
        address payable[] memory addresses = _getPayoutAddresses();
        uint256[] memory bps = _getPayoutBps();
        IERC20 erc20;
        uint256 balance;
        uint256 sending;
        for (uint256 t = 0; t < tokenAddresses.length; t++) {
            erc20 = IERC20(tokenAddresses[t]);
            balance = erc20.balanceOf(address(this));
            require(balance > 10000, "PA1D: Not enough tokens to transfer");
            for (uint256 i = 0; i < addresses.length; i++) {
                sending = ((bps[i] * balance) / 10000);
                require(erc20.transfer(addresses[i], sending), "PA1D: Couldn't transfer token");
            }
        }
    }

    /**
     * @dev This function validates that the call is being made by an authorised wallet.
     * @dev Will revert entire tranaction if it fails.
     */
    function _validatePayoutRequestor() internal view {
        if (!isOwner()) {
            bool matched;
            address payable[] memory addresses = _getPayoutAddresses();
            address payable sender = payable(msg.sender);
            for (uint256 i = 0; i < addresses.length; i++) {
                if (addresses[i] == sender) {
                    matched = true;
                    break;
                }
            }
            require(matched, "PA1D: sender not authorized");
        }
    }

    /**
     * @notice Set the wallets and percentages for royalty payouts.
     * @dev Function can only we called by owner, admin, or identity wallet.
     * @dev Addresses and bps arrays must be equal length. Bps values added together must equal 10000 exactly.
     * @param addresses An array of all the addresses that will be receiving royalty payouts.
     * @param bps An array of the percentages that each address will receive from the royalty payouts.
     */
    function configurePayouts(address payable[] memory addresses, uint256[] memory bps)
        public
        onlyOwner
    {
        require(addresses.length == bps.length, "PA1D: missmatched array lenghts");
        uint256 totalBp;
        for (uint256 i = 0; i < addresses.length; i++) {
            totalBp = totalBp + bps[i];
        }
        require(totalBp == 10000, "PA1D: bps down't equal 10000");
        _setPayoutAddresses(addresses);
        _setPayoutBps(bps);
    }

    /**
     * @notice Show the wallets and percentages of payout recipients.
     * @dev These are the recipients that will be getting royalty payouts.
     * @return addresses An array of all the addresses that will be receiving royalty payouts.
     * @return bps An array of the percentages that each address will receive from the royalty payouts.
     */
    function getPayoutInfo()
        public
        view
        returns (address payable[] memory addresses, uint256[] memory bps)
    {
        addresses = _getPayoutAddresses();
        bps = _getPayoutBps();
    }

    /**
     * @notice Get payout of all ETH in smart contract.
     * @dev Distribute all the ETH(minus gas fees) to payout recipients.
     */
    function getEthPayout() public {
        _validatePayoutRequestor();
        _payoutEth();
    }

    /**
     * @notice Get payout for a specific token address. Token must have a positive balance!
     * @dev Contract owner, admin, identity wallet, and payout recipients can call this function.
     * @param tokenAddress An address of the token for which to issue payouts for.
     */
    function getTokenPayout(address tokenAddress) public {
        _validatePayoutRequestor();
        _payoutToken(tokenAddress);
    }

    /**
     * @notice Get payout for a specific token name. Token must have a positive balance!
     * @dev Contract owner, admin, identity wallet, and payout recipients can call this function.
     * @dev Avoid using this function at all costs, due to high gas usage, and no guarantee for token support.
     * @param tokenName A string of the token name for which to issue payouts for.
     */
    function getTokenPayoutByName(string memory tokenName) public {
        _validatePayoutRequestor();
        address tokenAddress = PA1D(payable(getRegistry().getPA1D())).getTokenAddress(tokenName);
        require(!Address.isZero(tokenAddress), "PA1D: Token address not found");
        _payoutToken(tokenAddress);
    }

    /**
     * @notice Get payouts for tokens listed by address. Tokens must have a positive balance!
     * @dev Each token balance must be equal or greater than 10000. Otherwise calculating BP is difficult.
     * @param tokenAddresses An address array of tokens to issue payouts for.
     */
    function getTokensPayout(address[] memory tokenAddresses) public {
        _validatePayoutRequestor();
        _payoutTokens(tokenAddresses);
    }

    /**
     * @notice Get payouts for tokens listed by name. Tokens must have a positive balance!
     * @dev Each token balance must be equal or greater than 10000. Otherwise calculating BP is difficult.
     * @dev Avoid using this function at all costs, due to high gas usage, and no guarantee for token support.
     * @param tokenNames A string array of token names to issue payouts for.
     */
    function getTokensPayoutByName(string[] memory tokenNames) public {
        _validatePayoutRequestor();
        uint256 length = tokenNames.length;
        address[] memory tokenAddresses = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            address tokenAddress = PA1D(payable(getRegistry().getPA1D())).getTokenAddress(
                tokenNames[i]
            );
            require(!Address.isZero(tokenAddress), "PA1D: Token address not found");
            tokenAddresses[i] = tokenAddress;
        }
        _payoutTokens(tokenAddresses);
    }

    /**
     * @notice Inform about supported interfaces(eip-165).
     * @dev Provides the supported interface ids that this contract implements.
     * @param interfaceId Bytes4 of the interface, derived through bytes4(keccak256('sampleFunction(uin256,address)')).
     * @return True if function is supported/implemented, false if not.
     */
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        if (
            // EIP2981
            // bytes4(keccak256('royaltyInfo(uint256,uint256)')) == 0x2a55205a
            interfaceId == 0x2a55205a ||
            // Rarible V1
            // bytes4(keccak256('getFeeBps(uint256)')) == 0xb7799584
            interfaceId == 0xb7799584 ||
            // Rarible V1
            // bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
            interfaceId == 0xb9c4d9fb ||
            // Manifold
            // bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
            interfaceId == 0xbb3bafd6 ||
            // Foundation
            // bytes4(keccak256('getFees(uint256)')) == 0xd5a06d4c
            interfaceId == 0xd5a06d4c ||
            // SuperRare
            // bytes4(keccak256('tokenCreator(address,uint256)')) == 0xb85ed7e4
            interfaceId == 0xb85ed7e4 ||
            // SuperRare
            // bytes4(keccak256('calculateRoyaltyFee(address,uint256,uint256)')) == 0x860110f5
            interfaceId == 0x860110f5 ||
            // Zora
            // bytes4(keccak256('marketContract()')) == 0xa1794bcd
            interfaceId == 0xa1794bcd ||
            // Zora
            // bytes4(keccak256('tokenCreators(uint256)')) == 0xe0fd045f
            interfaceId == 0xe0fd045f ||
            // Zora
            // bytes4(keccak256('bidSharesForToken(uint256)')) == 0xf9ce0582
            interfaceId == 0xf9ce0582
        ) {
            return true;
        }
        return false;
    }

    /**
     * @notice Set the royalty information for entire contract, or a specific token.
     * @dev Take great care to not make this function accessible by other public functions in your overlying smart contract.
     * @param tokenId Set a specific token id, or leave at 0 to set as default parameters.
     * @param receiver Wallet or smart contract that will receive the royalty payouts.
     * @param bp Uint256 of royalty percentage, provided in base points format.
     */
    function setRoyalties(
        uint256 tokenId,
        address payable receiver,
        uint256 bp
    ) public onlyOwner {
        if (tokenId == 0) {
            _setDefaultReceiver(receiver);
            _setDefaultBp(bp);
        } else {
            _setReceiver(tokenId, receiver);
            _setBp(tokenId, bp);
        }
        address[] memory receivers = new address[](1);
        receivers[0] = address(receiver);
        uint256[] memory bps = new uint256[](1);
        bps[0] = bp;
        emit SecondarySaleFees(tokenId, receivers, bps);
    }

    // IEIP2981
    function royaltyInfo(uint256 tokenId, uint256 value) public view returns (address, uint256) {
        if (_getReceiver(tokenId) == address(0)) {
            return (_getDefaultReceiver(), (_getDefaultBp() * value) / 10000);
        } else {
            return (_getReceiver(tokenId), (_getBp(tokenId) * value) / 10000);
        }
    }

    // Rarible V1
    function getFeeBps(uint256 tokenId) public view returns (uint256[] memory) {
        uint256[] memory bps = new uint256[](1);
        if (_getReceiver(tokenId) == address(0)) {
            bps[0] = _getDefaultBp();
        } else {
            bps[0] = _getBp(tokenId);
        }
        return bps;
    }

    // Rarible V1
    function getFeeRecipients(uint256 tokenId) public view returns (address payable[] memory) {
        address payable[] memory receivers = new address payable[](1);
        if (_getReceiver(tokenId) == address(0)) {
            receivers[0] = _getDefaultReceiver();
        } else {
            receivers[0] = _getReceiver(tokenId);
        }
        return receivers;
    }

    // Manifold
    function getRoyalties(uint256 tokenId)
        public
        view
        returns (address payable[] memory, uint256[] memory)
    {
        address payable[] memory receivers = new address payable[](1);
        uint256[] memory bps = new uint256[](1);
        if (_getReceiver(tokenId) == address(0)) {
            receivers[0] = _getDefaultReceiver();
            bps[0] = _getDefaultBp();
        } else {
            receivers[0] = _getReceiver(tokenId);
            bps[0] = _getBp(tokenId);
        }
        return (receivers, bps);
    }

    // Foundation
    function getFees(uint256 tokenId)
        public
        view
        returns (address payable[] memory, uint256[] memory)
    {
        address payable[] memory receivers = new address payable[](1);
        uint256[] memory bps = new uint256[](1);
        if (_getReceiver(tokenId) == address(0)) {
            receivers[0] = _getDefaultReceiver();
            bps[0] = _getDefaultBp();
        } else {
            receivers[0] = _getReceiver(tokenId);
            bps[0] = _getBp(tokenId);
        }
        return (receivers, bps);
    }

    // SuperRare
    // Hint taken from Manifold's RoyaltyEngine(https://github.com/manifoldxyz/royalty-registry-solidity/blob/main/contracts/RoyaltyEngineV1.sol)
    // To be quite honest, SuperRare is a closed marketplace. They're working on opening it up but looks like they want to use private smart contracts.
    // We'll just leave this here for just in case they open the flood gates.
    function tokenCreator(
        address, /* contractAddress*/
        uint256 tokenId
    ) public view returns (address) {
        address receiver = _getReceiver(tokenId);
        if (receiver == address(0)) {
            return _getDefaultReceiver();
        }
        return receiver;
    }

    // SuperRare
    function calculateRoyaltyFee(
        address, /* contractAddress */
        uint256 tokenId,
        uint256 amount
    ) public view returns (uint256) {
        if (_getReceiver(tokenId) == address(0)) {
            return (_getDefaultBp() * amount) / 10000;
        } else {
            return (_getBp(tokenId) * amount) / 10000;
        }
    }

    // Zora
    // we indicate that this contract operates market functions
    function marketContract() public view returns (address) {
        return address(this);
    }

    // Zora
    // we indicate that the receiver is the creator, to convince the smart contract to pay
    function tokenCreators(uint256 tokenId) public view returns (address) {
        address receiver = _getReceiver(tokenId);
        if (receiver == address(0)) {
            return _getDefaultReceiver();
        }
        return receiver;
    }

    // Zora
    // we provide the percentage that needs to be paid out from the sale
    function bidSharesForToken(uint256 tokenId)
        public
        view
        returns (Zora.BidShares memory bidShares)
    {
        // this information is outside of the scope of our
        bidShares.prevOwner.value = 0;
        bidShares.owner.value = 0;
        if (_getReceiver(tokenId) == address(0)) {
            bidShares.creator.value = _getDefaultBp();
        } else {
            bidShares.creator.value = _getBp(tokenId);
        }
        return bidShares;
    }

    /**
     * @notice Get the storage slot for given string
     * @dev Convert a string to a bytes32 storage slot
     * @param slot The string name of storage slot(without the 'eip1967.PA1D.' prefix)
     * @return A bytes32 reference to the storage slot
     */
    function getStorageSlot(string calldata slot) public pure returns (bytes32) {
        return bytes32(uint256(keccak256(abi.encodePacked("eip1967.PA1D.", slot))) - 1);
    }

    /**
     * @notice Get the smart contract address of a token by common name.
     * @dev Used only to identify really major/common tokens. Avoid using due to gas usages.
     * @param tokenName The ticker symbol of the token. For example "USDC" or "DAI".
     * @return The smart contract address of the token ticker symbol. Or zero address if not found.
     */
    function getTokenAddress(string memory tokenName) public view returns (address) {
        return _getTokenAddress(tokenName);
    }

    /**
     * @notice Forwards unknown function call to the CXIP hotfixes smart contract(if present)
     * @dev All unrecognized functions are delegated to hotfixes smart contract which can be utilized to deploy on-chain hotfixes
     */
    function _defaultFallback() internal {
        /**
         * @dev Very important to note the use of sha256 instead of keccak256 in this function. Since the registry is made to be front-facing and user friendly, the choice to use sha256 was made due to the accessibility of that function in comparison to keccak.
         */
        address _target = getRegistry().getCustomSource(
            sha256(abi.encodePacked("eip1967.CXIP.hotfixes"))
        );

        /**
         * @dev To minimize gas usage, pre-calculate the 32 byte hash and provide the final hex string instead of running the sha256 function on each call inside the smart contract
         */
        // address _target = getRegistry().getCustomSource(0x45f5c3bc3dbabbfab15d44af18b96716cf5bec748c58d54d61c4e7293de6763e);
        /**
         * @dev Assembly is used to minimize gas usage and pass the data directly through
         */
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _target, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @notice Forwarding all unknown functions to default fallback
     */
    fallback() external {
        _defaultFallback();
    }

    /**
     * @dev This is intentionally left empty, to make sure that ETH transfers succeed.
     */
    receive() external payable {}
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 &&
            codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
    }

    function isZero(address account) internal pure returns (bool) {
        return (account == address(0));
    }
}

library Zora {
    struct Decimal {
        uint256 value;
    }

    struct BidShares {
        // % of sale value that goes to the _previous_ owner of the nft
        Decimal prevOwner;
        // % of sale value that goes to the original creator of the nft
        Decimal creator;
        // % of sale value that goes to the seller (current owner) of the nft
        Decimal owner;
    }
}

// This is a 256 value limit (uint8)
enum UriType {
    ARWEAVE, // 0
    IPFS, // 1
    HTTP // 2
}

// This is a 256 value limit (uint8)
enum InterfaceType {
    NULL, // 0
    ERC20, // 1
    ERC721, // 2
    ERC1155 // 3
}

struct Verification {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

struct CollectionData {
    bytes32 name;
    bytes32 name2;
    bytes32 symbol;
    address royalties;
    uint96 bps;
}

struct Token {
    address collection;
    uint256 tokenId;
    InterfaceType tokenType;
    address creator;
}

struct TokenData {
    bytes32 payloadHash;
    Verification payloadSignature;
    address creator;
    bytes32 arweave;
    bytes11 arweave2;
    bytes32 ipfs;
    bytes14 ipfs2;
}

interface ICxipERC {
    function admin() external view returns (address);

    function getIdentity() external view returns (address);

    function isAdmin() external view returns (bool);

    function isOwner() external view returns (bool);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);
}

interface ICxipIdentity {
    function addSignedWallet(
        address newWallet,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function addWallet(address newWallet) external;

    function connectWallet() external;

    function createERC721Token(
        address collection,
        uint256 id,
        TokenData calldata tokenData,
        Verification calldata verification
    ) external returns (uint256);

    function createERC721Collection(
        bytes32 saltHash,
        address collectionCreator,
        Verification calldata verification,
        CollectionData calldata collectionData
    ) external returns (address);

    function createCustomERC721Collection(
        bytes32 saltHash,
        address collectionCreator,
        Verification calldata verification,
        CollectionData calldata collectionData,
        bytes32 slot,
        bytes memory bytecode
    ) external returns (address);

    function init(address wallet, address secondaryWallet) external;

    function getAuthorizer(address wallet) external view returns (address);

    function getCollectionById(uint256 index) external view returns (address);

    function getCollectionType(address collection) external view returns (InterfaceType);

    function getWallets() external view returns (address[] memory);

    function isCollectionCertified(address collection) external view returns (bool);

    function isCollectionRegistered(address collection) external view returns (bool);

    function isNew() external view returns (bool);

    function isOwner() external view returns (bool);

    function isTokenCertified(address collection, uint256 tokenId) external view returns (bool);

    function isTokenRegistered(address collection, uint256 tokenId) external view returns (bool);

    function isWalletRegistered(address wallet) external view returns (bool);

    function listCollections(uint256 offset, uint256 length)
        external
        view
        returns (address[] memory);

    function nextNonce(address wallet) external view returns (uint256);

    function totalCollections() external view returns (uint256);

    function isCollectionOpen(address collection) external pure returns (bool);
}

interface ICxipRegistry {
    function getAsset() external view returns (address);

    function getAssetSigner() external view returns (address);

    function getAssetSource() external view returns (address);

    function getCopyright() external view returns (address);

    function getCopyrightSource() external view returns (address);

    function getCustomSource(bytes32 name) external view returns (address);

    function getCustomSourceFromString(string memory name) external view returns (address);

    function getERC1155CollectionSource() external view returns (address);

    function getERC721CollectionSource() external view returns (address);

    function getIdentitySource() external view returns (address);

    function getPA1D() external view returns (address);

    function getPA1DSource() external view returns (address);

    function getProvenance() external view returns (address);

    function getProvenanceSource() external view returns (address);

    function owner() external view returns (address);

    function setAsset(address proxy) external;

    function setAssetSigner(address source) external;

    function setAssetSource(address source) external;

    function setCopyright(address proxy) external;

    function setCopyrightSource(address source) external;

    function setCustomSource(string memory name, address source) external;

    function setERC1155CollectionSource(address source) external;

    function setERC721CollectionSource(address source) external;

    function setIdentitySource(address source) external;

    function setPA1D(address proxy) external;

    function setPA1DSource(address source) external;

    function setProvenance(address proxy) external;

    function setProvenanceSource(address source) external;
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}