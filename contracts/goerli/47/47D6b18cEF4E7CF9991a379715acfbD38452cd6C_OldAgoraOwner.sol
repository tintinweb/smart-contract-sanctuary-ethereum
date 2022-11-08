// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC1155 {
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

contract OldAgoraOwner {
    IERC1155 nftContract;
    address owner;

    constructor(IERC1155 _nftContract) {
        nftContract = _nftContract;
        owner = msg.sender;
    }

    function mintAll() public {
        require(msg.sender == owner);
        nftContract.mint(0xd42B5B2c5c6B289e3C020193D18CF71780a928D3, 2, 1, "");
        nftContract.mint(0x66108b8a884541272824629870103d34749Fb050, 2, 1, "");
        // nftContract.mint(0x7deAeA1b550FdDaF96EE902ccc84A1c1D8e4FFf5, 3, 1, "");
        // nftContract.mint(0x161a8a85964864c6F287FDcAca168B03c12F0944, 3, 1, "");
        // nftContract.mint(0x9cBd901E9c8d6D680e74F0269386224428B37E19, 1, 1, "");
        // nftContract.mint(0x0E7a6eaBc0486B135CDcdca851aFdE01dbba03C6, 3, 1, "");
        // nftContract.mint(0xcd828A1aA572dEBd6d736432067607007573671F, 2, 1, "");
        // nftContract.mint(0xB45f2CF4DD346faA03f7C6eb9646Ff4b97e40f1b, 3, 1, "");
        // nftContract.mint(0xC78300388aec3d65991A2Ab9D0b2d5F4f4254c2d, 3, 1, "");
        // nftContract.mint(0x924Ac7D94aA9Df1Baf29401616A24Ea867774722, 1, 1, "");
        // nftContract.mint(0x33Df0e6B20EA9Bb4F6b253e3571aDcd8C9110954, 2, 1, "");
        // nftContract.mint(0x2A199c411a65b7E5531C54bc0c91dEC97824C8e3, 3, 1, "");
        // nftContract.mint(0x29F9B20207D5dB0802F8D85b24Deba4ff22c1EB8, 2, 1, "");
        // nftContract.mint(0x583c688A200A4B0C00587e2Eb2f7d2be26057F52, 3, 1, "");
        // nftContract.mint(0xa5E8D98b637b1825780dB916240d96b885bb804e, 3, 1, "");
        // nftContract.mint(0xA5Af5C596b948f37A7a50941CFc1f50C54F620d2, 3, 1, "");
        // nftContract.mint(0x4009f182ABf0A3269a80F34fc6d1d585866733D4, 2, 1, "");
        // nftContract.mint(0x06e8F9f7eAA02a6c19E08B73fD91Fe33a55E9C7e, 1, 1, "");
        // nftContract.mint(0x052A2317f99bc92d38389ED8e454CEf43e20273D, 1, 1, "");
        // nftContract.mint(0x1bdBB1E1D6dFEe927e51ed7106e79dB7E16FD9a9, 3, 1, "");
        // nftContract.mint(0x2D01778D6d0DFD2866c27EC273e9f97D17d9E3Fa, 3, 1, "");
        // nftContract.mint(0x52f52Ff92E9A59D4b68D1711893ddDe7eb05E9D3, 3, 1, "");
        // nftContract.mint(0xeCC548B3536a1674603c2e54DD5CfB749D8c5Cab, 3, 1, "");
        // nftContract.mint(0xCeE19CC05DFaF31198975954D28ed3AB0A85DdC8, 1, 1, "");
        // nftContract.mint(0xCeE19CC05DFaF31198975954D28ed3AB0A85DdC8, 2, 1, "");
        // nftContract.mint(0xe6d25d945BC88d22940d9b38B5465CA4154227a2, 3, 1, "");
        // nftContract.mint(0x90fE1E05497654F0AaD8537d0B0C3b6F6c1A2d79, 1, 1, "");
        // nftContract.mint(0x6ABB3aD9DDb1f02D2DC633c3859dA524FD08D2Bc, 3, 1, "");
        // nftContract.mint(0xef6810eEAF52E0d8197fb8c34a72503F16cC6e43, 3, 1, "");
        // nftContract.mint(0x6B3fa095a3e05A49E1BD02da465628eAa25B2E1B, 2, 1, "");
        // nftContract.mint(0x65e3a578bfdD0Cd9f324830e73Ff087108e89dae, 3, 1, "");
        // nftContract.mint(0x7cb6521568c915821eDed76fa93317b1366535E8, 1, 1, "");
        // nftContract.mint(0x0aad103Ab00Ece96C412f1A4d5F718fC40B2b141, 1, 1, "");
        // nftContract.mint(0x02E07c35c838b8C53bC5bEa282b073c6F1D487f6, 3, 1, "");
        // nftContract.mint(0x81EF799270A6aDd2e9f606cdf62371022D288970, 3, 1, "");
        // nftContract.mint(0x21e0FC0E03e8BEECEDe40f541dd0dbAf8C7AC507, 3, 1, "");
        // nftContract.mint(0x99f9bC94d4F94533AA5536c02A62C26Bb790497b, 3, 1, "");
        // nftContract.mint(0xC9A17fB13808C5C45ba572af3B0f8F6102706f76, 3, 1, "");
        // nftContract.mint(0x161a8a85964864c6F287FDcAca168B03c12F0944, 3, 1, "");
        // nftContract.mint(0x0EA48b80497cEf5db3d24C961FEBaa5c52Ef523b, 1, 1, "");
        // nftContract.mint(0x9cffd986335da85AB5FEd5063493156cDf762A21, 3, 1, "");
        // nftContract.mint(0xC34AE18b1775ae9530F9e1bA565BF0e88280AD5a, 3, 1, "");
        // nftContract.mint(0x1B69e1D1B9c1c327A6c1D9e1E0aBB8a75370e504, 1, 1, "");
        // nftContract.mint(0x73eABBE2bc6070D3Fb2F38c860a3978dd85872e5, 1, 1, "");
        // nftContract.mint(0x1B69e1D1B9c1c327A6c1D9e1E0aBB8a75370e504, 1, 1, "");
        // nftContract.mint(0x161a8a85964864c6F287FDcAca168B03c12F0944, 3, 1, "");
        // nftContract.mint(0x1B69e1D1B9c1c327A6c1D9e1E0aBB8a75370e504, 1, 1, "");
        // nftContract.mint(0x632AcB952b8B3187B13db7979948f20EE9695384, 3, 1, "");
        // nftContract.mint(0x161a8a85964864c6F287FDcAca168B03c12F0944, 3, 1, "");
        // nftContract.mint(0x491F97c3A380009bACDd6834cF352A42765b8D19, 3, 1, "");
        // nftContract.mint(0x7Cc4B4c95073eD9478a637C658c57C1077d547cC, 2, 1, "");
        // nftContract.mint(0x82c6d2D35BfAB654D5d3eCe76e489Daaf94eFd76, 3, 1, "");
        // nftContract.mint(0x161a8a85964864c6F287FDcAca168B03c12F0944, 1, 1, "");
        // nftContract.mint(0x161a8a85964864c6F287FDcAca168B03c12F0944, 1, 1, "");
        // nftContract.mint(0x85cb6E2921Dc518c22FB68F1154BA6752ae1f5Da, 1, 1, "");
        // nftContract.mint(0x47a3Af0276982016Bb332d5c0Ef6A6da024eDa79, 3, 1, "");
        // nftContract.mint(0x21D872F95164BCeBd4D0Dd3faEa810D7a452972E, 2, 1, "");
        // nftContract.mint(0x8cebA7517a853C7013F6dDF9B159513b1e42E1B7, 3, 1, "");
        // nftContract.mint(0x3Df91bE03C3EAe16454626F76EC30E6BE8100dCe, 3, 1, "");
        // nftContract.mint(0x9F6B2eBA24317F64256Eaa20Da7d093487D03501, 3, 1, "");
    }
}