/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.13;

/// @title SpiceDAO Deposit
/// @author 0xNotes
/// @notice Only to be used for the Ancient Enemies Deposit List.
contract Deposit {
    bool internal locked;
    bool public active = true;
    address owner;
    mapping(address => uint256) public addressToMintCount;
    mapping(address => uint256) public addressToDeposit;
    address[] public refundlist;
    address[] public depositlist;

    address[] public whitelist = [
        0xD92dA91c48cAE1D8309DA06150751C11D049613E,
        0x2Ad67bA7A0Bc86977741b1e797277b246c7Fb0e8,
        0xd360b14A3C7237Ae0E03164552Fd914b275A0679,
        0xbB52453bF1B11f0E9EfDAa088e786DAF4a85997d,
        0x98189b35a3A8B736EC9A12Da5767B9d1F58eD886,
        0x9b0223084D36937E45b43CB99941C701be502142,
        0x1c3c5305Eeaf72B3d6D20D1c20bcbC894FFeafeE,
        0x6F9E433d7E0ff7169871D54E00bf6878A7de555B,
        0xF79765D064B86648C7C01F55f9eCB5ec5D3A7d4b,
        0x3eE39Ad4295b579ddee749D63Bf0d7507676f4d4,
        0x38c1c9C6D2b90f820C9677f931792FE82760AAc2,
        0x36B95d4B0233Cb14A420E16A386c7150eAa1ab55,
        0x5b115FB974ee8215B51Ac02bAb3Ca479f6683A39,
        0x36680CEaEA6854F1E3Eb609Aff48545D4F6746E7,
        0xd71c042312fd8800ade805E14F746A58BEac569A,
        0x3a2D9C943045E2eF73301bcD22aB574720611a90,
        0x144c02f5370Be541e123Fa5cF9083E30Ab7c5a04,
        0x8D1e0459651Cfa22007d5890C8346bB766CBE3B1,
        0x4556c171dC77dA167Cad8b42EbCcb35A9984f3e4,
        0xbF598D7755Af45592C3b985477C147365B2DAeBA,
        0x950Cd838d9e5994D197967328e5aC0Ae8Fd5D9ad,
        0x289D6ac47BF1EBE497dcDDb934FF43aF8E4b84c8,
        0x9C3196f8C884c2F7Cb2BB3c769FfF8D7E479CD82,
        0xa15Fab718b0cB25F82d61F58c014bD88a87EEED2,
        0x51764790B30b49358a3b2e6f30Ad77484b885b90,
        0x5f28648C01eDA3aC15a2ce1759f7cd7a36C874D3,
        0x6Bc411F602253f5a9946818cA72c8932aCE7A937,
        0x0E3D909B726cBE8FfDc0DA161A30245BE403a7c5,
        0x8638907B822893358B7574A04C477b51Ac782B4f,
        0xa91d9ab328779591e999fEcd16816AbEDc85B7FF,
        0x8d6fe1ea16811ea76A39B5CC0481872E75186311,
        0x654acb9bF947dcE25F06c73976037270c460007D,
        0x2A9E47aed3225606b2c0a5b341cdc5Ef4A527ddB,
        0xC59D029C4561493bE0Da9D068f825be375c7648B,
        0xa5DCEdc1a461d8b1Ed64dfdeb4fbfb0D5493C27b,
        0x5e679D5903809a62d6dABe2EcFd58A9722D34C79,
        0x94705A9d675daa924F9190Eca4c05ED6B12d5345,
        0x2a15f1FEd563C9C815eB510dcb4A3475a087894d,
        0x9c4f52cf0f6537031d64B0C8BA7ea1729f0d1087,
        0x0e55C20d2BC315E879e602A1da70cdF46EAb57b6,
        0x2259c4E885f8Ea070C9EFB9451FFe5fC4E82eED6,
        0x688847Fc6Addd42F176080ed2081BBb67c276408,
        0xA6Ea80bDea3786E915CC951A4D0962BE884D5e11,
        0x0dFE0a0943009bB6A68c1ab9E3622a950f963285,
        0x0F615319D7CeeD5801faF6b13C9034DE9223a3eC,
        0xFf5dCd67b90b51eDDb8B2Cb4Fc7689e48Ac903A2,
        0xC3B4be23e868822bAA198Ee3041c9F9e535BF0C1,
        0x55957F99bc906dB62B8c57E0512d57361c4E2966,
        0x9007D5C8c0F2E772D5DF9447562da53D302766eD,
        0xFe223C26D16BAE2EdE49A634DA3710a8e5b32c32,
        0xd1dD546b28925f3d61461399807135bBfC75A6bB,
        0x4C843a3D077C353533b81aD2435268C8611fDF16,
        0xC1dD86f0EC0D6fC897FBb64bF0559570595A930D,
        0xE780A34002214698722c7eF0d60da10875913887,
        0x2a0897c724808567E161f458c4f7521c8aDA8556,
        0xff4E10c59734B2f20a39327C3661E0DCBa0db923,
        0x4c021Ba2d12FdB42061BB3181cC71dEBd1b0c426,
        0x076c4DfaBFB34eBe8A4336deB8B222F6D128C261,
        0x5f25ce9FeF6762B73eD117f16456524c0dDfA7E2,
        0x5dF459F917168b64c0cD9187968527d31f1b3E3c,
        0x6aC029Ae2e792a56354C544347F38d68db618492,
        0xd0aB0300Ae36001Fd8C3Fd7712B6173CCbfD1554,
        0x220eE648EBE5bb4FE52CB24898d51E4449EFA42b,
        0x82c1E79AFe4CfA5b29795e3DE0e7F203c793E6c1,
        0x3d844c391e7806157aE42D653d1D7E2919926a61,
        0x7776fEd706a0e761a41A08cd3607E646EF780a68,
        0xCe0776ad81694e57EA4D2b6B39f86338A8b73381,
        0x85F3d5456a48E09C4b9feeA00e7f3567a848b4E4,
        0x296a012981C1C9f5665c3ddca84c42173fe75a6E,
        0x9b5f50146a361f82b1fedf63C5d04d4918a730C3,
        0xFFCD4c0F81322e19b6edaB52ac3375730901661D,
        0xC3AE4D28C204Fb07B80CDd8b2D9aDA361D82992B,
        0x9785640B43Bd182FAA0b0fE9B1db036e21D534bB,
        0x716c52795D00E45C1476ACa40e1Ef18153fCF092,
        0x5bfF3D2435b541e2285738699eD809b736b70737,
        0xd0360eAa75e86c43e1fB7C08AC6f1ee6cAA0DA5d,
        0x0fa0E7f46E4B760494cA6e3B3992e4DFb343dA95,
        0xe6B67036b1a14FF7126717aA4fd0AfC6BEE4D797,
        0x66498B318c0f97edc9c52426f2409024a4C4Bd99,
        0x07f70642CB786277Cc568B359B2d8f3222a4B018,
        0x5473D9C09D7C52b980945904039551626fA48a74,
        0x8deF36bA09af68cec83f89dE7A16a6300fd2074d,
        0x64dEDABA6199110C86bB30127164933A85977902,
        0xf89AD1AF3506a47F08672dEf43191B291dF18677,
        0x93951907913e8c7C79b77bD4E91B2D701D5A8efD,
        0xdF1458Bd1ADd294acD1892aA52E7Da8cAF9D3ed5,
        0xF25F9AE2b3528baB9C7aE39615B088a4e087f10C,
        0x6661280D2363f69A615AE69f57aDF936a89644ca,
        0x2ed0c280559072D4EAf6F8b71Bc277f8DE406A7C,
        0x96Cb84ac416602cec04B6778fa3F8e588e84cc95,
        0xED4eBcd8D790824708E16ced47Aa508887a4328D,
        0xd46f5A31282C4e52C4c30C1b5a24A2dF99b5a2D8,
        0x550a7B674c50fCB7708aBF10A00eDB1a8f746894
    ];

    uint256[] public claimedDeposit = [
        0.1 ether,
        0.2 ether,
        0.1 ether,
        0.5 ether,
        0.5 ether,
        0.2 ether,
        0.3 ether,
        0.1 ether,
        0.2 ether,
        0.2 ether,
        0.3 ether,
        0.3 ether,
        0.3 ether,
        0.2 ether,
        0.1 ether,
        0.1 ether,
        0.3 ether,
        0.1 ether,
        0.3 ether,
        0.4 ether,
        0.2 ether,
        0.1 ether,
        0.3 ether,
        0.2 ether,
        0.5 ether,
        0.3 ether,
        0.2 ether,
        0.1 ether,
        0.2 ether,
        0.3 ether,
        0.1 ether,
        0.5 ether,
        0.3 ether,
        0.1 ether,
        0.3 ether,
        0.2 ether,
        0.1 ether,
        0.2 ether,
        0.4 ether,
        0.5 ether,
        0.3 ether,
        0.2 ether,
        0.2 ether,
        0.1 ether,
        0.2 ether,
        0.5 ether,
        0.1 ether,
        0.1 ether,
        0.1 ether,
        0.1 ether,
        0.3 ether,
        0.4 ether,
        0.1 ether,
        0.2 ether,
        0.1 ether,
        0.2 ether,
        0.5 ether,
        0.5 ether,
        0.5 ether,
        0.1 ether,
        0.2 ether,
        0.2 ether,
        0.4 ether,
        0.4 ether,
        0.5 ether,
        0.5 ether,
        0.2 ether,
        0.2 ether,
        0.2 ether,
        0.2 ether,
        0.2 ether,
        0.1 ether,
        0.4 ether,
        0.5 ether,
        0.3 ether,
        0.2 ether,
        0.2 ether,
        0.1 ether,
        0.3 ether,
        0.5 ether,
        0.1 ether,
        0.3 ether,
        0.2 ether,
        0.1 ether,
        0.2 ether,
        0.1 ether,
        0.1 ether,
        0.2 ether,
        0.1 ether,
        0.2 ether,
        0.5 ether,
        0.1 ether,
        0.5 ether
    ];

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    /// @notice Called when eth is provided with our without msg.data filled.
    fallback() external payable {
        require(active, "Deposit Contract Inactive");
        require(!isRefundlisted(), "Already Refunded");
        require(isWhitelisted(), "Not On Whitelist");
        (bool valid, uint256 count) = getValidDeposit(msg.value);
        require(valid, "Invalid Contribution Amount");
        depositlist.push(msg.sender);
        addressToMintCount[msg.sender] = count;
        addressToDeposit[msg.sender] = msg.value;
        delete whitelist[getWhitelistIndex()];
    }

    /// @notice Users can get refunds from this contract while active.
    function refund() public noReentrant {
        require(active, "Deposit Contract Inactive");
        require(isDepositlisted(), "Not On Deposit List");
        require(
            address(this).balance > 0,
            "Out Of Funding! Please Notify Team!"
        );
        delete depositlist[getDepositlistIndex()];
        refundlist.push(msg.sender);
        (bool sent, ) = address(msg.sender).call{
            value: addressToDeposit[msg.sender]
        }("");
        require(sent, "Failed to send Ether");
    }

    /// @param to the address that will receive the balance
    /// @notice Used to transfer balance to another address
    function transferBalance(address to) public onlyOwner {
        (bool sent, ) = payable(to).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    /// @notice Used to toggle a campaigns active state, will return false if true, true if false
    function activeToggle() public onlyOwner {
        active = !active;
    }

    /// @notice Used to return deposit list
    function getDepositList() public view onlyOwner returns (address[] memory) {
        return depositlist;
    }

    /// @notice Used to return whitelist
    function getWhitelist() public view returns (address[] memory) {
        return whitelist;
    }

    /// @notice Used to return claimed deposit list
    function getClaimedDepositList() public view returns (uint256[] memory) {
        return claimedDeposit;
    }

    /// @notice Used to return mint count for eth address
    /// @param a address to get mint count for
    function getCountMapping(address a) public view returns (uint256) {
        return addressToMintCount[a];
    }

    /// @notice Used to return deposit given an eth address
    /// @param a address to get mint count for
    function getDepositMapping(address a) public view returns (uint256) {
        require(isDepositlisted(), "Not A Depositor!");
        return addressToDeposit[a];
    }

    /// @notice Gets index of user in whitelist. Used also to verify claimedBurnAmount numbers.
    /// @return index The Index of Message Sender, reverts if not whitelisted
    function getWhitelistIndex() public view returns (uint256 index) {
        require(isWhitelisted(), "Not On Whitelist");
        for (uint256 i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == msg.sender) {
                return i;
            }
        }
    }

    /// @notice Gets index of user in deposit list.
    /// @return index The Index of Message Sender, reverts if not deposit listed
    function getDepositlistIndex() public view returns (uint256 index) {
        require(isDepositlisted(), "Not On Deposit List");
        for (uint256 i = 0; i < depositlist.length; i++) {
            if (depositlist[i] == msg.sender) {
                return i;
            }
        }
    }

    /// @notice Gets message senders whitelist status.
    /// @return whitelisted True if on Deposit whitelist, False if not on Deposit whitelist
    function isWhitelisted() public view returns (bool whitelisted) {
        for (uint256 i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    /// @notice Gets message senders Deposit List status.
    /// @return funder True if on Deposit List, False if not on Deposit List
    function isDepositlisted() public view returns (bool funder) {
        for (uint256 i = 0; i < depositlist.length; i++) {
            if (depositlist[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    /// @notice Gets message senders refundlist status.
    /// @return refunded True if on Refund List, False if not on Refund List
    function isRefundlisted() public view returns (bool refunded) {
        for (uint256 i = 0; i < refundlist.length; i++) {
            if (refundlist[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    /// @return valid The boolean status of if the deposit is for a valid amount
    /// @return count The NFT Mint count for the user
    function getValidDeposit(uint256 val)
        public
        view
        returns (bool valid, uint256 count)
    {
        require(
            val <= claimedDeposit[getWhitelistIndex()],
            "Contribution greater than Claimed Deposit Amount!"
        );
        for (uint256 i = 0; i < 5; i++) {
            if (
                val ==
                [0.1 ether, 0.2 ether, 0.3 ether, 0.4 ether, 0.5 ether][i]
            ) {
                return (true, i + 1);
            }
        }
        return (false, 0);
    }

    /// @notice Updates whitelist and claimed deposit amount list
    /// @dev Ensure same order as newClaimedBurnAmount and same number of entries AND are in the same order
    /// @param newWhitelist The new whitelist for another campaign
    /// @param newClaimedDeposit The new Claimed Deposit Amount for another group of users
    function updateLists(
        address[] memory newWhitelist,
        uint256[] memory newClaimedDeposit
    ) public onlyOwner {
        require(
            newWhitelist.length == newClaimedDeposit.length,
            "Lists Not Same Length! PLEASE CHECK"
        );
        updateWhitelist(newWhitelist);
        updateClaimedDeposit(newClaimedDeposit);
    }

    /// @param newWhitelist New whitelist to be appended to old white list
    function updateWhitelist(address[] memory newWhitelist) internal {
        address[] memory returnArr = new address[](
            whitelist.length + newWhitelist.length
        );

        uint256 i = 0;
        for (i; i < whitelist.length; i++) {
            returnArr[i] = whitelist[i];
        }

        uint256 j = 0;
        while (j < newWhitelist.length) {
            returnArr[i++] = newWhitelist[j++];
        }

        whitelist = returnArr;
    }

    /// @param newClaimedDeposit New claimed deposit amount to be appended to old claimed deposit list
    function updateClaimedDeposit(uint256[] memory newClaimedDeposit) internal {
        uint256[] memory returnArr = new uint256[](
            claimedDeposit.length + newClaimedDeposit.length
        );

        uint256 i = 0;
        for (i; i < claimedDeposit.length; i++) {
            returnArr[i] = claimedDeposit[i];
        }

        uint256 j = 0;
        while (j < newClaimedDeposit.length) {
            returnArr[i++] = newClaimedDeposit[j++];
        }

        claimedDeposit = returnArr;
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  $$$$$$\            $$\                     $$$$$$$\   $$$$$$\   $$$$$$\
// $$  __$$\           \__|                    $$  __$$\ $$  __$$\ $$  __$$\
// $$ /  \__| $$$$$$\  $$\  $$$$$$$\  $$$$$$\  $$ |  $$ |$$ /  $$ |$$ /  $$ |
// \$$$$$$\  $$  __$$\ $$ |$$  _____|$$  __$$\ $$ |  $$ |$$$$$$$$ |$$ |  $$ |
//  \____$$\ $$ /  $$ |$$ |$$ /      $$$$$$$$ |$$ |  $$ |$$  __$$ |$$ |  $$ |
// $$\   $$ |$$ |  $$ |$$ |$$ |      $$   ____|$$ |  $$ |$$ |  $$ |$$ |  $$ |
// \$$$$$$  |$$$$$$$  |$$ |\$$$$$$$\ \$$$$$$$\ $$$$$$$  |$$ |  $$ | $$$$$$  |
//  \______/ $$  ____/ \__| \_______| \_______|\_______/ \__|  \__| \______/
//           $$ |
//           $$ |                                            DEPOSIT
//           \__|                                            -0xNotes
//
////////////////////////////////////////////////////////////////////////////////////////////////////