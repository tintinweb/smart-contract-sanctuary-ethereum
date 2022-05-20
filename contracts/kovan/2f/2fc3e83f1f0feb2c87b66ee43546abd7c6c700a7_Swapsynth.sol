/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

//
// Swapsynth
// Interface: Swapship.org VSDC.info
// Virtual Stable Digital Coin: Synthetic Swap Contract V1
// April 2022
//

// //////////////////////////////////////////////////////////////////////////////// //
//                                                                                  //
//                               ////   //////   /////                              //
//                              //        //     //                                 //
//                              //        //     /////                              //
//                                                                                  //
//                              Never break the chain.                              //
//                                   www.RTC.wtf                                    //
//                                                                                  //
// //////////////////////////////////////////////////////////////////////////////// //

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

pragma solidity ^0.8.4;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function devsdcription() external view returns (string memory);
    function version() external view returns (uint256);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// File: contracts/VSDC.sol

pragma solidity ^0.8.0;

interface VSDC {
    function balanceOf(address usr) external view returns (uint);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function mint(address usr, uint wad) external returns (bool);
    function burnFrom(address src, uint wad) external returns (bool);
}

// Copyright (C) 2021 RTC/Veronika
// SPDX-License-Identifier: No License
// File: contracts/Swapsynth01.sol

pragma solidity ^0.8.4;

contract Swapsynth {
    VSDC public vsdc;

    struct Asset {
        uint id;
        bytes32 symbol;
        address token;
        address oracle;
    }

    uint private _lid = 0;
    address public _vsdc = 0xF757c584aF5846446d0989775D68Ef7DD963Df55;

    mapping (address => bool) public contractors;
    mapping (address => bool) public owners;
    mapping (address => uint) public blocks;
    mapping (address => uint) public volumes;

    mapping (bytes32 => Asset) public assets;
    mapping (address => mapping (bytes32 => uint)) public balances;

    event  Buy(bytes32 symbol, uint val);
    event  Sell(bytes32 symbol, uint val);
    event  AddOwner(address indexed src, address indexed usr);
    event  RemoveOwner(address indexed src, address indexed usr);

    constructor() {
        owners[msg.sender] = true;
        vsdc = VSDC(_vsdc);

        addAsset(keccak256("BTC"), address(0), 0x6135b13325bfC4B00278B4abC5e20bbce2D6580e);
        addAsset(keccak256("ETH"), address(0), 0x9326BFA02ADD2366b30bacB125260Af641031331);
        addAsset(keccak256("LTC"), address(0), 0xCeE03CF92C7fFC1Bad8EAA572d69a4b61b6D4640);

        addAsset(keccak256("UNI"), address(0), 0xDA5904BdBfB4EF12a3955aEcA103F51dc87c7C39);
        addAsset(keccak256("LINK"), address(0), 0x396c5E36DD0a0F5a5D33dae44368D4193f69a1F0);
        addAsset(keccak256("COMP"), address(0), 0xECF93D14d25E02bA2C13698eeDca9aA98348EFb6);

        addAsset(keccak256("CHF"), address(0), 0xed0616BeF04D374969f302a34AE4A63882490A8C);
        addAsset(keccak256("EUR"), address(0), 0x0c15Ab9A0DB086e062194c273CC79f41597Bbf13);
        addAsset(keccak256("GBP"), address(0), 0x28b0061f44E6A9780224AA61BEc8C3Fcb0d37de9);

        addAsset(keccak256("XAU"), address(0), 0xc8fb5684f2707C82f28595dEaC017Bfdf44EE9c5);
        addAsset(keccak256("XAG"), address(0), 0x4594051c018Ac096222b5077C3351d523F93a963);
        addAsset(keccak256("OIL"), address(0), 0x48c9FF5bFD7D12e3C511022A6E54fB1c5b8DC3Ea);
    }

    function getPrice(address oracle) public view returns (uint) {
        AggregatorV3Interface feed = AggregatorV3Interface(oracle);
        uint prx = 0;
        
        (
            uint80 roundID, 
            int ticker,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = feed.latestRoundData();

        if(ticker < 0) {
            prx = uint(-ticker) * 1e10;
        }
        else {
            prx = uint(ticker) * 1e10;
        }

        delete roundID;
        delete ticker;
        delete startedAt;
        delete timeStamp;
        delete answeredInRound;
        
        return prx;
    }

    function control() internal view returns (bool) {
        require((msg.sender == tx.origin) || contractors[msg.sender] == true, "Access denied");
        require((blocks[msg.sender] < block.number) || contractors[msg.sender] == true, "Block used");
        return true;
    }

    function addAsset(bytes32 _symbol, address _token, address _oracle) public {
        require(owners[msg.sender] == true);
        assets[_symbol] = Asset(_lid, _symbol, _token, _oracle);

        _lid += 1;
    }

    function editAsset(uint _id, bytes32 _symbol, address _token, address _oracle) public {
        require(owners[msg.sender] == true);
        assets[_symbol] = Asset(_id, _symbol, _token, _oracle);
    }

    function buyAsset(bytes32 _symbol, uint _size, bool _bal) public {
        require(control());
        require(_size > 0, "No size");

        address oracle = assets[_symbol].oracle;
        require(oracle != address(0), "No oracle");

        uint prx = getPrice(oracle);
        require(prx > 0, "No price");

        uint val = prx * _size / 1e18;

        if (_bal == true) {
            require(balances[msg.sender][keccak256("VSDC")] >= val, "No VSDC");

            balances[msg.sender][keccak256("VSDC")] -= val;
            balances[msg.sender][_symbol] += _size;
        }
        else {
            require(vsdc.balanceOf(msg.sender) >= val, "No VSDC");

            vsdc.burnFrom(msg.sender, val);
            balances[msg.sender][_symbol] += _size;
        }

        blocks[msg.sender] = block.number;
        volumes[msg.sender] += val;

        emit Buy(_symbol, _size);
    }

    function sellAsset(bytes32 symbol, uint size, bool bal) public {
        require(control());
        require(size > 0, "No size");
        require(balances[msg.sender][symbol] >= size, "No asset");

        address oracle = assets[symbol].oracle;
        require(oracle != address(0), "No oracle");

        uint prx = getPrice(oracle);
        require(prx > 0, "No price");

        uint val = prx * size / 1e18;

        if (bal == true) {
            balances[msg.sender][keccak256("VSDC")] += val;
        }
        else {
            vsdc.mint(msg.sender, val);
        }

        balances[msg.sender][symbol] -= size;
        blocks[msg.sender] = block.number;
        volumes[msg.sender] += val;

        emit Sell(symbol, size);
    }

    function deposit(uint _size) public {
        require(control());
        require(_size > 0, "No size");
        require(vsdc.balanceOf(msg.sender) >= _size, "No VSDC");

        vsdc.burnFrom(msg.sender, _size);
        balances[msg.sender][keccak256("VSDC")] += _size;

        blocks[msg.sender] = block.number;
        volumes[msg.sender] += _size;
    }

    function withdraw(uint _size) public {
        require(control());
        require(_size > 0, "No size");
        require(balances[msg.sender][keccak256("VSDC")] >= _size, "No VSDC");

        vsdc.mint(msg.sender, _size);
        balances[msg.sender][keccak256("VSDC")] -= _size;

        blocks[msg.sender] = block.number;
        volumes[msg.sender] += _size;
    }

    function controlContractors(address _contractor, bool _access) public {
        require(owners[msg.sender] == true);
        contractors[_contractor] = _access;
    }

    function addOwner(address _usr) public {
        require(owners[msg.sender] == true);
        owners[_usr] = true;

        emit AddOwner(msg.sender, _usr);
    }

    function removeOwner(address _usr) public {
        require(owners[msg.sender] == true);
        owners[_usr] = false;

        emit RemoveOwner(msg.sender, _usr);
    }
}