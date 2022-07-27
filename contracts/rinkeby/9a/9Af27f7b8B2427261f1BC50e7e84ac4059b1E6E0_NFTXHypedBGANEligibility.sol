// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./eligibility/NFTXEligibility.sol";


contract NFTXHypedBGANEligibility is NFTXEligibility {
    
    event NFTXEligibilityInit();

    uint256[45] private bastardHypeData = [
        60073777500531777309569341902311450832970806684984335380877167411848999105,
        911030518599144363128045939364018710001346374805208504959662892107039264,
        110427941575966967351359660042133073187106177110108689088109851709579264,
        7244072965591375751291519753228743911444121263833947131949686290901482078208,
        53920716187111647673158152691530347090981044843371481999282330927104,
        28269553155187587904379845452183588808913619556543343451846675079410746368,
        7237012485818621482766969856862286591708568850762763481418421878898739380288,
        28948022336288995524024183204685263395539079038253687811956299320406017310720,
        508851981616123375297400616180849883477860677580438602377384428085745090560,
        14134793368296585640660899053986903458853787334949849965302457659035746634,
        904625697166532776746840654726597851124159588974703084599473238529721204992,
        7689649709741820280138983570393374265558559592432921588791700801021244604416,
        15378664459238105110628985953637648885546204368019600629895762625608282570754,
        28298022766565589858196639354849931654303230842856485297897134577510535172,
        13493137370082929871893548962295401850961908172137736658014378656770,
        227757629473013495911990931968352473098775479022254484690657366071443520,
        56594320043695478757479259204605731921712130427921800033634632805818388480,
        1234136656686932226634729421412400046043143420946502433395179520,
        61627625835149618753101568217953080766429142083270315994710955118825035728960,
        7251140367541087207091562649092212227169199184044871573547234918439107690496,
        452347414605298385028233695601748739592923762703385251917908360463567028224,
        883437012362525740351793614791135273097040343676404640010951746595604992,
        9046256978523790763950594814262484907683338705294530755777835808993233076224,
        3450900324220477694505668625892552192974936730546741369102118470811648,
        57430294129484326263779550669392017430943804262482366905002778858449010756,
        65821820616593864908747109345958364366624049286605470886667616288,
        1812788541022450744194479714188894866769936947868592939254390553980459548672,
        43423800311479600834842931609725708698380332594266411088983739638829207789584,
        3618502804043390528626632892318197405868212980259278026803612618127891234816,
        56552909565628402194510254494583770532182463364142439563339590932115767296,
        26959947596161696637747483674810921589898199962629595310899557601280,
        904632626720312509776015060208753544895833407483695121281400256143343747072,
        113078643504963296618490795471347341004721143874259254595939388655763980304,
        57303256417331751398208122226062325776996986023712946383428138303744,
        57896044648988654776538961467054346974585413820871518656470882686887182467104,
        886874563544683924429857749297433117598767741861474362313171780969431296,
        1766847117436137102385241768710430707025467705021728368456105290766221312,
        16288594161741084010661460287002386974227278478751649599946725574991446802560,
        883423585046944938649989785825506761682762488072976323836115426887073808,
        113520790000297878528676916947969078388139197042543667816101704655236498484,
        62115717943867358877497987304365777498653201364686319841865591427178496,
        57896942277043151534397650742294364288415203933952110676029965772475051671552,
        65147192089934725678015384173470249969788419746629932641898133147403780358144,
        452368062554040716058966371635471166633704285680304924422196653263178170384,
        1649402183680
    ];
    
    function name() public pure override virtual returns (string memory) {    
        return "HypedBGANs";
    }

    function finalized() public view override virtual returns (bool) {    
        return true;
    }

   function targetAsset() public pure override virtual returns (address) {
        return 0x31385d3520bCED94f77AaE104b406994D8F2168C;
   }

    function __NFTXEligibility_init_bytes(bytes memory /* configData */) public override virtual initializer {
        __NFTXEligibility_init();
    }

    function __NFTXEligibility_init() public initializer {
        emit NFTXEligibilityInit();
    }

    function _checkIfEligible(uint256 tokenId) internal view override virtual returns (bool) {
        if (tokenId > 11304) {
            return false;
        }

        return (bastardHypeData[tokenId / 256] & (1 << (tokenId % 256))) > 0;
    }

}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFTXEligibility {
    // Read functions.
    function name() external pure returns (string memory);
    function finalized() external view returns (bool);
    function targetAsset() external pure returns (address);
    function checkAllEligible(uint256[] calldata tokenIds)
        external
        view
        returns (bool);
    function checkEligible(uint256[] calldata tokenIds)
        external
        view
        returns (bool[] memory);
    function checkAllIneligible(uint256[] calldata tokenIds)
        external
        view
        returns (bool);
    function checkIsEligible(uint256 tokenId) external view returns (bool);

    // Write functions.
    function __NFTXEligibility_init_bytes(bytes calldata configData) external;
    function beforeMintHook(uint256[] calldata tokenIds) external;
    function afterMintHook(uint256[] calldata tokenIds) external;
    function beforeRedeemHook(uint256[] calldata tokenIds) external;
    function afterRedeemHook(uint256[] calldata tokenIds) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../proxy/Initializable.sol";
import "../interface/INFTXEligibility.sol";

// This is a contract meant to be inherited and overriden to implement eligibility modules. 
abstract contract NFTXEligibility is INFTXEligibility, Initializable {
  function name() public pure override virtual returns (string memory);
  function finalized() public view override virtual returns (bool);
  function targetAsset() public pure override virtual returns (address);
  
  function __NFTXEligibility_init_bytes(bytes memory initData) public override virtual;

  function checkIsEligible(uint256 tokenId) external view override virtual returns (bool) {
      return _checkIfEligible(tokenId);
  }

  function checkEligible(uint256[] calldata tokenIds) external override virtual view returns (bool[] memory) {
      uint256 length = tokenIds.length;
      bool[] memory eligibile = new bool[](length);
      for (uint256 i; i < length; i++) {
          eligibile[i] = _checkIfEligible(tokenIds[i]);
      }
      return eligibile;
  }

  function checkAllEligible(uint256[] calldata tokenIds) external override virtual view returns (bool) {
      uint256 length = tokenIds.length;
      for (uint256 i; i < length; i++) {
          // If any are not eligible, end the loop and return false.
          if (!_checkIfEligible(tokenIds[i])) {
              return false;
          }
      }
      return true;
  }

  // Checks if all provided NFTs are NOT eligible. This is needed for mint requesting where all NFTs 
  // provided must be ineligible.
  function checkAllIneligible(uint256[] calldata tokenIds) external override virtual view returns (bool) {
      uint256 length = tokenIds.length;
      for (uint256 i; i < length; i++) {
          // If any are eligible, end the loop and return false.
          if (_checkIfEligible(tokenIds[i])) {
              return false;
          }
      }
      return true;
  }

  function beforeMintHook(uint256[] calldata tokenIds) external override virtual {}
  function afterMintHook(uint256[] calldata tokenIds) external override virtual {}
  function beforeRedeemHook(uint256[] calldata tokenIds) external override virtual {}
  function afterRedeemHook(uint256[] calldata tokenIds) external override virtual {}

  // Override this to implement your module!
  function _checkIfEligible(uint256 _tokenId) internal view virtual returns (bool);
}