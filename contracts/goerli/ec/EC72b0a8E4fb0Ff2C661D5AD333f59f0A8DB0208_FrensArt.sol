// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

//import "hardhat/console.sol";
import "./interfaces/IStakingPool.sol";
import "./interfaces/IFrensPoolShare.sol";
import "./interfaces/IFrensMetaHelper.sol";
import "./interfaces/IFrensArt.sol";
import "./FrensBase.sol";

contract FrensArt is IFrensArt, FrensBase {

  IFrensPoolShare frensPoolShare;

  constructor(IFrensStorage _frensStorage) FrensBase(_frensStorage){
    frensPoolShare = IFrensPoolShare(getAddress(keccak256(abi.encodePacked("contract.address", "FrensPoolShare"))));
    version = 0;
  }

  // Visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(uint256 id) public view returns (string memory) {
    //IStakingPool stakingPool = IStakingPool(payable(getAddress(keccak256(abi.encodePacked("pool.for.id", id)))));
    IFrensMetaHelper metaHelper = IFrensMetaHelper(getAddress(keccak256(abi.encodePacked("contract.address", "FrensMetaHelper"))));
    string memory depositString = metaHelper.getDepositStringForId(id);
    string memory pool = metaHelper.getPoolString(id);
    //uint shareForId = stakingPool.getDistributableShare(id);
    //string memory shareString = metaHelper.getEthDecimalString(shareForId);
    //string memory poolColor = metaHelper.getColor(address(stakingPool));
    //address ownerAddress = frensPoolShare.ownerOf(id);
    //string memory textColor = metaHelper.getColor(ownerAddress);
    //(bool ensExists, string memory ownerEns) = metaHelper.getEns(stakingPool.owner());

    string memory render = string(abi.encodePacked(
/*
      //logo 
      '<image x="100" y="58" xlink:href="data:image/png;base64,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"/>'

      //curves for text
      '<path id="curve" d="M93,306 a151,151 0 1,1 1,1 " fill="transparent" />',
      '<path id="curve2" d="M200,30 a170,170 0 1,0 1,0 " fill="transparent" />',
      
      //deposit & claimable text
      '<text font-size="25"  x="354" text-anchor="middle" fill="#4554EA"   font-family="Sans-Serif" >',
        '<textPath xlink:href="#curve">',
          'Deposit: ', depositString, ' Eth ', 
          '<tspan dx="30">',
            ' Claimable: ', shareString, ' Eth',
          '</tspan>',
        '</textPath>',
      '</text>',
      
      //pool owners ENS
      '<text font-size="25"  x="534" text-anchor="middle" fill="#4554EA" font-family="Sans-Serif" >',
        '<textPath  xlink:href="#curve2">',
          ensExists ? 'Pool created by: ' : 'frens.fun',
          ownerEns,
          '</textPath>',
      '</text>'   
      */

      '<defs>',
        '<linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">',
          '<stop offset="0%" style="stop-color:#3f19ee;stop-opacity:1" />',
          '<stop offset="100%" style="stop-color:#54dae0;stop-opacity:1" />',
        '</linearGradient>',
    
        '<style>',
          '@font-face{',
                'font-family:"Permanent Marker";',
                'src:url(data:application/font-woff;charset=utf-8;base64,d09GRgABAAAAABFgAA0AAAAAGYAAAQBCAAAAAAAAAAAAAAAAAAAAAAAAAABPUy8yAAABMAAAAE8AAABgYbLjo2NtYXAAAAGAAAAAbwAAAWoWSx6gY3Z0IAAAAfAAAAACAAAAAgAVAABmcGdtAAAB9AAAAPcAAAFhkkHa+mdseWYAAALsAAAL0QAAESgSox0daGVhZAAADsAAAAA2AAAANgiVWwdoaGVhAAAO+AAAAB0AAAAkBHcB5GhtdHgAAA8YAAAANAAAADQf0gAbbG9jYQAAD0wAAAAcAAAAHBhmHXZtYXhwAAAPaAAAAB4AAAAgAhoCGW5hbWUAAA+IAAABuwAAA1RQW8M9cG9zdAAAEUQAAAAUAAAAIP+2AEBwcmVwAAARWAAAAAcAAAAHaAaMhXicY2BhKmKcwMDKwMC0h6mLgYGhB0Iz3mUwZgRymRhgoIGBQV2AAQFcPP2CGBwYFBhCmPL+H2awZSlgdAUKgzQxMBUyfQNSCgwMAGX6DJAAeJxjYGBgZoBgGQZGBhBIAfIYwXwWBg8gzcfAwcDEwMagwODI4MbgwxDAEPL/P1AcxHdl8GbwYwj6////w/8H/+/7v+v/zv87oOYgAUY2dBFMgKEJHTCB3MkCYrGyMbBzcDJwcfMQNnbQAADIvxMRAAAVAAB4nF2QPU7EMBCFYxIWcgMkC8kjaylWtuipUjiRUJqwofA0/Ei7Etk7IKWhccFZ3nYpczEE3gRWQOPxe6P59GaQmBp54/dCvPMgPt/gLvd5+vhgIYxSZecgnixODMSKLFKjKqTLau01q6DC7SaoSr08b5Atpxob28DXCknru/jee0LB8vjdMt9YZAdMNmECR8DuG7CbAHH+w+LU1ArpVePvPHonUTiWRKrE2HiMThKzxeKYMdbX7mJOe2awWFmcz4TWo5BIOIRZaUIfggxxgx89/tWDSP4bxW8jXqAcRN9MnV6TPBiaNMWE7CxyU7e+jBGJ7RflYGtcAHicdVdLjyTZWc37fsaNR0ZG5KsiK59RWV1dVV1ZlTld3V3jmpfaMu4Zj7AtWTAjDQgQksUII4TkBUuQEPwAxJYNC3bAHpaskEBsWCJvjGyMkb1Aojk3K3sGIdF1uyqeN+79vnPOd75O5//5R1//4PXP6T/SH3T+tPMXnU77NrkjO4zV9W5/8Dap78im3h80cUxIcziK46revv3l6YSoQNT+UAWmzkm7uiC77ao9JxdxsnYl8cB8dkGv47Xdqg0kpeHw3n704h8ZL873b8U5WiLV9iquB2fx/jAhg5sj0zWEhlybXqYcN6qYboY+E5XvnThBGeWSCMOFt5b6LOFU8iwVVNLCusdjSigXzI6W54OQCC0SzjCJ5OW0KengOKvPhnnXMUFF4IpwQXlCGeEW71PF47ypspyliVOJT63klFJOLkOiEjV/PtddJwbn6ae29+LzZ91VyY0sj/PypGsJZSx9epJbJrlInHGF6a0H5bo8uukTQYhnkhGsXxDV7Z0kyuvyUT1cT3uEaS6pTLW3TPHa6MGxUFwaPE2xrTJ1XqcqoVRTZxinrrRZkyZaMx7XTonHPjXWJ0i3rAihUi2/3trR3TjigHQMcPBn9F87f9jpxDifs90da++QfrY7x0E83VVXm2pzvbq5asi2RZ6rQMo6CLUKFKlUlayr7a6SvYbt9hBoT0krV2o129+9o8DRLt5jO8BDruYB+X1LY9FKMUaNwT6YVlnR1XmK3frZ+nJ0+QsvX22I4EwTqgQnflVj8TRbn29utkOdhNzrnhOEnf7aE8JNlhdecFGu1pdjoYSdurAMxbFfby83y8H92IYkOMGY1N2LZ1997FI9/vqrlzNdqbRdr3OTpZlGRKvVYllny1VbFnVqZJo7Y5gCHihlojeyRiujR02mTZYBF5wqyVyluaH4uCxyR2zlkxECBJgJIYZPj5E8STymyXMPWHlF2tPaaSqEpcU+B6//7fXP6L/QH3f++iEHiHgk1oGR23hpFonzwKftdbt6m2zfMBbjarvb7jlbbTdXbyhZgTEpWc3ms4BF4qeSe47VKhJv/+Izomp1oHZK21Uk6QMhkaOZPJCzluW8jCe96uHWG4JGjsbvnjXHlHWH4yQVTljEWEsC2gkJqKdGgGVeUs4otcTWl3V92dddrTzLs+azFz3p5XVuMyU0007JoJIk0c2HH7860gmTyDghpAccgIplW42fTlrjJHCDFwi7kLab68L0j7NqXThObWkiJ5UghsSkWcGrNEs11uVBJGE58kf53+d34/4oN0iR5jzTrnImCEHwMSBDe6E9sJlIn1AL6ulMKgblkFxX4Co5hgoIRXW/9kAAUUnXSUE4eCicHMwsB1sp8q8MyQBwyxJnn2uGFe33oRQhkuFRiEZBiQ6SS1bU3SMNHkBurMStYOYXtQ4Hjv6UXUCr/wT4uHuI+p6XDdsgdbsGnH6gJFMxsWy3rertKkIjgoHVYa/LGA9JxWvb1eH6Pp0Q6PaQUFAWj53T9vqcQqi3+L1dlQQJtUJMlkuf5HldmjRkhktRJKW2BbSNuwLAPnp1VM8XbWnBS03yUWrLXAL2hDvef7K5GcmimwuEkaesuH35i48FkWkJ1tDN6e23TkEzXSqzznttypyYX5w9WbosBOOc0M6qGDRO/oZDszl9/iuffPpWsljOHBFRUgVz0/nUSCkEN6OmSZrrOjsa1CE+zrQI0g1Ikvi80N1QTZvjnoEkWEK01e0J0gDAhCw3F88KanNiIa6Mj30+LQWr7t99hmJjaRj0Smuk8j7RRB5y85/0d+gPO9896Cd9IONuT43DiIfI1CYWSPlFzftyRNpGHiNdm1vyJYNLtU/RfKYOfHyg53yGVD1FVQgZds6osJZboJ342pXLVENxeO9pmSddhBqM0gFcpJAhID30qbeJX3zzdN5YoFqKMEyTgTcaKe56bLLsNYtwFNIm9VbMPjx5tuB8yZ3Jzy4ue9Z1l94NY4Wc3ze733wuUVFdN02nQ0PreVYshsoKmYhJ252/f8Z4AZYC7tBe4czGcS0T1GwiXVRU/HdVY2TUwJ+8/m/6z4jj9xBHVBBZ1XANqEDX1eZBEoFX1JSGyBJ32irQGsqGv6Sq37AhRm4P9PqNjLWoTZgNMwQ2D+yvLJdpFxwM3tSTOjeQdqGO3nn33cn45mwSbQJEAAjC0ALIAQbiKtWjm0luXGKMLgZVvwh9LoECx7zVxFSiW3lglxiRDyfr6ZNXtbVaoyBb8Yke9HMQX+NHLc/Oc07sQN/9wR/98Xt2tLhowAUgVis8ErIkTfA9MrzZ3U4GH332+a07ns0DzXsFK5e17fdL1VxfbY+PXgzTs4pD5ITXw0r5xSdfYWVVmDRFRaEd8fo/EMv/6nyz8/1Op5Zg8+qO7lCID7pxEzF59aU+XG0PalBWdRWNnGwoijx9g1CGOs4Q2AZ1Y3O9eQD1ObmJYY1jFh0dov2Ts5dP14kZb98/VkZBibEhYVPQrCqDSwKqbDoLxIcQ1RFODIKovYe6jM+PaCQY5b5MsssyHOfJYrVKF+9N7WjYJeXu9rbWpy9bkRHBhqsB9Yr5NJXz98eYSJant9P3fuuTj1dMwvcZ77yhFo4psf0uoXlmNQs+cd7xyHer/AjlAyu8+PWLMBoOk7xdTHQ5yLWCintFE0t+t16uHh3l8BKGt6UvcuNBm5WwyiopxtdzRmOsF6//nf4l/VHng84vdzrdbbUv4KSOAcfJHbnZhxwGKUp1VGrEMYY2opvs9XV1U21Wd2S120f4AOZzKh8T6BbXNMpXXjt4zwyobWZlePTkusKurz4cd2ddms1/9XvfvwUNe0X5KNepg9MQIbrGxMgfw5ZALT0N4/EYND1uXHjr/p4MOZRvZIQl1Wo2zVEx3Sgbbs6mxpeOSGrkeNC8/7WPTs5u5lUyevHidkBQAQzxw8HAqpQXV0/WP3U51FmCCnCkShmbuKQUsWbRjn39T/CVP+r8xp7RYCL2CLpin+1DgYqM3WtdLzK7oT1sv7xSkcVsH6hqW+/tIjxp+wBExAxgRtwU4kYeqt05GcNhOIWsKCEYIUnqUx8mYnL55O68/7yrUx26aTCUoDd48e3PTgxtpkfzyWQ+Ph65ICFPRihrE7v4/NuPtiezihF4vTJzGiy2jskELzLyjeR40henv7QWp98iua6W82nBXN6Vk3fuX4yo0/337q9E3h7BBaXJvD3JpTFO39yvj3IuiyrFAg38rGuakUb0RQiehOE0Gw6OSiLJydWQQUUE3KLJiQFYyT90J9N2JJb58vG+1ljUmr9FTH8fSLuLMIuhvJ5FfO3F7xCjgy2X1UMwYyC/aM5Wchfd975J286vUaxihT8n2zfygHPwen4eHfyDKcCziADMEzXLs8ueptvv/vbvvcND6omH5esnj7+zcM30OLgF9kFVf1CyYgjhR/fD4WmYzb/yje+cccdMPRolOoFwCUo4geFC9ZJh/dX7Z2OWBB89FocwDG9L389Pvzan0qmU/F3adVmRDReDHPXOrhrV9VWvdG7Q0yjLkntiQHcFdyWNkghc3h85WL102m0u67MPbtoETQSCji4pc8TBtzMGpTWDYa15Np4GtAcpLqNnIjQpnNagTCoxaR7j3nn9Q3aM2vTniPs+JDfRbW/QFn1hvSOgoyxurqpDq5zC25CDjY42/P8W/pSEBzdQS7X314d+uoqVX87b1RtLdkG2N//LbuNbu+u9ucCU8AZI9SM6U6fxN57FqBBWEb0kfGiuVx+dnt8gzq4uxHB7dPJxmzfBc3SNRxwBs85axWE5vW4+mPbPCpsZkyl01NBurljMB4LCUedRsdEGS6qVlXlxGkAcH0smXibaMJRS2hS2UE7hEtpnpCbxhusAv+RVQB+ArhYeXzh6rRPtx11rWEGi+0USJUlk7LFRBIzy0i/mFh0s7DN6WB3LxfCkLNeDYtrLT0Kq0Lt74fAiGgjlUK5lrNPEL8qaKJQWRaMtlZa7YXCF+uDTx/2rocNHBgnsPCHo3khsBx1hnc7/AEkkdOYAAAAAAQAAAAEAQjJeBUpfDzz1CAsEAAAAAADJNUogAAAAANUrzNf/5v/VAy8C+wAAAAkAAgAAAAAAAHicY2BkYGAp+LebQZ5Z+v8zBhBgZEAFvAB0MARfAAAAAXsAAAF7AAACz//mAoIACQJN/+wDGwAJAogACQK9//EC+gAFAo8AJAKWAAoCTgAKAm4AAAAAAAYADAEQAdIC4gOwBFQE+gWwBjwG5geiCJR4nGNgZGBg4GXYzsDEAAKMYJKLAchlTAQxARYlATcAAHiclVHNattAEP7WcVIKremtpaehp6TE+vHROgXbAdHEGKfkriiLLKJIYqXY+NInyAvkLfoMPfQh+hh9gn5eL8GYlFItu/vNzDff7IwAvMNPKGy/iHuLFf2Rwx28wheHD/AJc4e7+IDW4UO8xaPDR3iPJ4d7+IzvzFLd17SW+OWwgqiZwx30VO3wAcbqm8NdBOqHw4f4qH47fASv88bhHr52hqOqXps8W7RynJ7IIAgDuVnLeVW2Ms5LbU4lLlNPzopCLK0RoxttlvrWm2lzn5SazMvE3Gkz19lDkZjQC4IwGsfTefTM2BL6jrGfKM5/rU2TV6VYhb/kLtq2Hvr+arXykjpJF9qrTOYXearLRjf+RTyaTK8m/YEXYIQKNdYwyJFhwXkLjpHihPcAAUJuwQ0ZgnNyS8sYk11CM+uUVkycwiM6Q8ElO2qNtTTvDXvJ85bMmbXukViVreYlLYM7G5nzzPBArY0vZEZg3xKxcowp49ELGrsK/T2Nf1WUPf619TbsY9Oz7Lzh/+puZtBywkP4XCu7PEZq7pRRTasiL2O0YLXUajZ2Yj4u2O0IE3Z8xbPPP8JX/AHcqKQbAHicY2BmAIP/mxmMGTABLwAstgH2uAH/hbAEjQA=) format("woff"); ',
                'font-weight:normal;',
                'font-style:normal;}',
        '</style>',
      '</defs>',
  
      '<rect height="400" width="400" fill="url(#grad1)" />',
      
      '<image x="125" y="80" transform="matrix(.90,0,0,.90,0,0)" opacity=".22"  xlink:href="data:image/png;base64,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"/>',
      
      '<image opacity=".3"  xlink:href="data:image/png;base64,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"/>',
      
      '<text font-size="15.5" x="200" y="163" text-anchor="middle" font-family="sans" letter-spacing="6" fill="white">',
        'DEPOSIT',
      '</text>',

      '<text font-size="45" x="200" y="212" text-anchor="middle"  font-weight="910" font-family="Sans,Arial" letter-spacing="-1" fill="white">',
        depositString, ' ETH ', 
      '</text>',
      
      '<text font-size="18.7" x="200" y="243" text-anchor="middle" font-family="Permanent Marker" fill="white">',
        'FRENS POOL STAKE',
      '</text>',
      
      '<rect x="27" y="345" height="30" width="346" fill="#4554EA" opacity=".4" />',

      '<text font-size="10" x="200" y="365" text-anchor="middle" font-weight="bold" font-family="Sans,Arial" fill="white">',
        pool,
      '</text>'
    ));

    return render;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IStakingPool{

  function owner() external view returns (address);

  function depositToPool() external payable;

  function addToDeposit(uint _id) external payable;

  function withdraw(uint _id, uint _amount) external;

  function distribute() external;

  function distributeAndClaim() external;

  function distributeAndClaimAll() external;

  function claim() external;

  function getIdsInThisPool() external view returns(uint[] memory);

  function getShare(uint _id) external view returns(uint);

  function getDistributableShare(uint _id) external view returns(uint);

  function getPubKey() external view returns(bytes memory);

  function setPubKey(
    bytes calldata pubKey,
    bytes calldata withdrawal_credentials,
    bytes calldata signature,
    bytes32 deposit_data_root
    ) external;

  function getState() external view returns(string memory);

  function getDepositAmount(uint _id) external view returns(uint);

  function stake(
    bytes calldata pubkey,
    bytes calldata withdrawal_credentials,
    bytes calldata signature,
    bytes32 deposit_data_root
  ) external;

  function stake() external;

    function exitPool() external;

}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";


interface IFrensPoolShare is IERC721Enumerable{

  function mint(address userAddress) external;

  function burn(uint tokenId) external;

  function exists(uint _id) external view returns(bool);

  function getPoolById(uint _id) external view returns(address);

  function tokenURI(uint256 id) external view returns (string memory);

  function renderTokenById(uint256 id) external view returns (string memory);

}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

interface IFrensMetaHelper {

  //function getColor(address a) external pure returns(string memory);

  function getEthDecimalString(uint amountInWei) external pure returns(string memory);

  function getOperatorsForPool(address poolAddress) external view returns (uint32[] memory, string memory);

  function getPoolString(uint id) external view returns (string memory);

  function getEns(address addr) external view returns(bool, string memory);

  function getDepositStringForId(uint id) external view returns(string memory);
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

interface IFrensArt {
  function renderTokenById(uint256 id) external view returns (string memory);
}

pragma solidity >=0.8.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

import "./interfaces/IFrensStorage.sol";

/// @title Base settings / modifiers for each contract in Frens Pool
/// @author modified 04-Dec-2022 by 0xWildhare originally by David Rugendyke (h/t David and Rocket Pool!)
/// this code is modified from the Rocket Pool RocketBase contract all "Rocket" replaced with "Frens"

abstract contract FrensBase {

    // Calculate using this as the base
    uint256 constant calcBase = 1 ether;

    // Version of the contract
    uint8 public version;

    // The main storage contract where primary persistant storage is maintained
    IFrensStorage frensStorage;


    /*** Modifiers **********************************************************/

    /**
    * @dev Throws if called by any sender that doesn't match a Frens Pool network contract
    */
    modifier onlyLatestNetworkContract() {
        require(getBool(keccak256(abi.encodePacked("contract.exists", msg.sender))), "Invalid or outdated network contract");
        _;
    }

    /**
    * @dev Throws if called by any sender that doesn't match one of the supplied contract or is the latest version of that contract
    */
    modifier onlyLatestContract(string memory _contractName, address _contractAddress) {
        require(_contractAddress == getAddress(keccak256(abi.encodePacked("contract.address", _contractName))), "Invalid or outdated contract");
        _;
    }

    /**
    * @dev Throws if called by any sender that isn't a registered node
    */
    //removed  0xWildhare
    /*
    modifier onlyRegisteredNode(address _nodeAddress) {
        require(getBool(keccak256(abi.encodePacked("node.exists", _nodeAddress))), "Invalid node");
        _;
    }
    */
    /**
    * @dev Throws if called by any sender that isn't a trusted node DAO member
    */
    //removed  0xWildhare
    /*
    modifier onlyTrustedNode(address _nodeAddress) {
        require(getBool(keccak256(abi.encodePacked("dao.trustednodes.", "member", _nodeAddress))), "Invalid trusted node");
        _;
    }
    */

    /**
    * @dev Throws if called by any sender that isn't a registered Frens StakingPool
    */
    modifier onlyStakingPool(address _stakingPoolAddress) {
        require(getBool(keccak256(abi.encodePacked("pool.exists", _stakingPoolAddress))), "Invalid Pool");
        _;
    }


    /**
    * @dev Throws if called by any account other than a guardian account (temporary account allowed access to settings before DAO is fully enabled)
    */
    modifier onlyGuardian() {
        require(msg.sender == frensStorage.getGuardian(), "Account is not a temporary guardian");
        _;
    }


    





    /*** Methods **********************************************************/

    /// @dev Set the main Frens Storage address
    constructor(IFrensStorage _frensStorage) {
        // Update the contract address
        frensStorage = IFrensStorage(_frensStorage);
    }


    /// @dev Get the address of a network contract by name
    function getContractAddress(string memory _contractName) internal view returns (address) {
        // Get the current contract address
        address contractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
        // Check it
        require(contractAddress != address(0x0), "Contract not found");
        // Return
        return contractAddress;
    }


    /// @dev Get the address of a network contract by name (returns address(0x0) instead of reverting if contract does not exist)
    function getContractAddressUnsafe(string memory _contractName) internal view returns (address) {
        // Get the current contract address
        address contractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
        // Return
        return contractAddress;
    }


    /// @dev Get the name of a network contract by address
    function getContractName(address _contractAddress) internal view returns (string memory) {
        // Get the contract name
        string memory contractName = getString(keccak256(abi.encodePacked("contract.name", _contractAddress)));
        // Check it
        require(bytes(contractName).length > 0, "Contract not found");
        // Return
        return contractName;
    }

    /// @dev Get revert error message from a .call method
    function getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }



    /*** Frens Storage Methods ****************************************/

    // Note: Unused helpers have been removed to keep contract sizes down

    /// @dev Storage get methods
    function getAddress(bytes32 _key) internal view returns (address) { return frensStorage.getAddress(_key); }
    function getUint(bytes32 _key) internal view returns (uint) { return frensStorage.getUint(_key); }
    function getString(bytes32 _key) internal view returns (string memory) { return frensStorage.getString(_key); }
    function getBytes(bytes32 _key) internal view returns (bytes memory) { return frensStorage.getBytes(_key); }
    function getBool(bytes32 _key) internal view returns (bool) { return frensStorage.getBool(_key); }
    function getInt(bytes32 _key) internal view returns (int) { return frensStorage.getInt(_key); }
    function getBytes32(bytes32 _key) internal view returns (bytes32) { return frensStorage.getBytes32(_key); }
    function getArray(bytes32 _key) internal view returns (uint[] memory) { return frensStorage.getArray(_key); }

    /// @dev Storage set methods
    function setAddress(bytes32 _key, address _value) internal { frensStorage.setAddress(_key, _value); }
    function setUint(bytes32 _key, uint _value) internal { frensStorage.setUint(_key, _value); }
    function setString(bytes32 _key, string memory _value) internal { frensStorage.setString(_key, _value); }
    function setBytes(bytes32 _key, bytes memory _value) internal { frensStorage.setBytes(_key, _value); }
    function setBool(bytes32 _key, bool _value) internal { frensStorage.setBool(_key, _value); }
    function setInt(bytes32 _key, int _value) internal { frensStorage.setInt(_key, _value); }
    function setBytes32(bytes32 _key, bytes32 _value) internal { frensStorage.setBytes32(_key, _value); }
    function setArray(bytes32 _key, uint[] memory _value) internal { frensStorage.setArray(_key, _value); }

    /// @dev Storage delete methods
    function deleteAddress(bytes32 _key) internal { frensStorage.deleteAddress(_key); }
    function deleteUint(bytes32 _key) internal { frensStorage.deleteUint(_key); }
    function deleteString(bytes32 _key) internal { frensStorage.deleteString(_key); }
    function deleteBytes(bytes32 _key) internal { frensStorage.deleteBytes(_key); }
    function deleteBool(bytes32 _key) internal { frensStorage.deleteBool(_key); }
    function deleteInt(bytes32 _key) internal { frensStorage.deleteInt(_key); }
    function deleteBytes32(bytes32 _key) internal { frensStorage.deleteBytes32(_key); }
    function deleteArray(bytes32 _key) internal { frensStorage.deleteArray(_key); }

    /// @dev Storage arithmetic methods - push added by 0xWildhare
    function addUint(bytes32 _key, uint256 _amount) internal { frensStorage.addUint(_key, _amount); }
    function subUint(bytes32 _key, uint256 _amount) internal { frensStorage.subUint(_key, _amount); }
    function pushUint(bytes32 _key, uint256 _amount) internal { frensStorage.pushUint(_key, _amount); }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity >=0.8.0 <0.9.0;


// SPDX-License-Identifier: GPL-3.0-only
//modified from IRocketStorage on 03/12/2022 by 0xWildhare

interface IFrensStorage {

    // Deploy status
    function getDeployedStatus() external view returns (bool);

    // Guardian
    function getGuardian() external view returns(address);
    function setGuardian(address _newAddress) external;
    function confirmGuardian() external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string memory);
    function getBytes(bytes32 _key) external view returns (bytes memory);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
    function getBytes32(bytes32 _key) external view returns (bytes32);
    function getArray(bytes32 _key) external view returns (uint[] memory);

    // Setters
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string calldata _value) external;
    function setBytes(bytes32 _key, bytes calldata _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;
    function setArray(bytes32 _key, uint[] calldata _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;
    function deleteArray(bytes32 _key) external;

    // Arithmetic (and stuff) - push added by 0xWildhare
    function addUint(bytes32 _key, uint256 _amount) external;
    function subUint(bytes32 _key, uint256 _amount) external;
    function pushUint(bytes32 _key, uint256 _amount) external;

    // Protected storage removed ~ 0xWildhare
    /*
    function getNodeWithdrawalAddress(address _nodeAddress) external view returns (address);
    function getNodePendingWithdrawalAddress(address _nodeAddress) external view returns (address);
    function setWithdrawalAddress(address _nodeAddress, address _newWithdrawalAddress, bool _confirm) external;
    function confirmWithdrawalAddress(address _nodeAddress) external;
    */
}