// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Compiler.sol";
import "./OnChainCheckRenderer_v2_interface.sol";
import "./GasLibs.sol";

contract OnchainCheckRendererV2AnimationUrl is IOnChainCheckRenderer_v2_Render, Ownable {
  IDataChunkCompiler private compiler;
  address[9] private threeAddresses;
  IERC721 private nft;
  string private rpc;

  // Maps tokenId to baseline gas price but 10x uint24 are packed into a single uint256
  // Therefor tokenIds are looked up by index / 10 and bit shifts are used to get the gas price 
  mapping(uint256 => uint256) private packedBaselineGasPrices;

  // Addresses in this order:
  // 0: DataChunkCompiler
  // 1: ThreeJSChunk1
  // 2: ThreeJSChunk2
  // 3: ThreeJSChunk3
  // 4: ThreeJSChunk4
  // 5: ThreeJSChunk5
  // 6: ThreeJSChunk6
  // 7: ThreeJSChunk7
  // 8: ThreeJSChunk8
  // 9: ThreeJSChunk9
  // 10: OnChainGasCheckNFT
  constructor(
    address[11] memory _addresses
  ) {
    compiler = IDataChunkCompiler(_addresses[0]);
    threeAddresses[0] = _addresses[1];
    threeAddresses[1] = _addresses[2];
    threeAddresses[2] = _addresses[3];
    threeAddresses[3] = _addresses[4];
    threeAddresses[4] = _addresses[5];
    threeAddresses[5] = _addresses[6];
    threeAddresses[6] = _addresses[7];
    threeAddresses[7] = _addresses[8];
    threeAddresses[8] = _addresses[9];
    nft = IERC721(_addresses[10]);
  }

  function setRpc(string memory _rpc) public onlyOwner {
    rpc = _rpc;
  }

  function getBaselineGasPrice(uint256 tokenId) public view returns (uint24) {
    uint256 packedGasPrices = packedBaselineGasPrices[tokenId / 10];
    uint256 index = tokenId % 10;
    return uint24(packedGasPrices >> (index * 24));
  }

  function setBaselineGasPrice(uint256 tokenId, uint256 gasPrice) public {
    // check if ownerOf or approvedForAll of the nft token
    require(
      nft.ownerOf(tokenId) == msg.sender || nft.isApprovedForAll(nft.ownerOf(tokenId), msg.sender),
      "Not owner or approved"
    );
    uint256 index = tokenId % 10;
    uint256 packedGasPrices = packedBaselineGasPrices[tokenId / 10];
    packedGasPrices = packedGasPrices & ~(uint256(0xFFFFFF) << (index * 24));
    packedGasPrices = packedGasPrices | (gasPrice << (index * 24));
    packedBaselineGasPrices[tokenId / 10] = packedGasPrices;
  }

  function render(
    uint256 tokenId,
    uint256 seed,
    uint24 gasPrice,
    bool /* isDarkMode */,
    bool[80] memory /* isCheckRendered */
  ) public view returns (string memory) {
    return
      string.concat(
        compiler.HTML_HEAD(),
        string.concat(
          compiler.BEGIN_SCRIPT_DATA_COMPRESSED(),
          compileThreejs(),
          compiler.END_SCRIPT_DATA_COMPRESSED(),
          compiler.BEGIN_SCRIPT(),
          scriptVars(tokenId, seed, gasPrice),
          compiler.SCRIPT_VAR(
            "rpc",
            string.concat("%2522", rpc, "%2522"),
            true
          ),
          compiler.END_SCRIPT()
        ),
        "%253Cstyle%253E%250A%2520%2520*%2520%257B%250A%2520%2520%2520%2520margin%253A%25200%253B%250A%2520%2520%2520%2520padding%253A%25200%253B%250A%2520%2520%257D%250A%2520%2520canvas%2520%257B%250A%2520%2520%2520%2520width%253A%2520100%2525%253B%250A%2520%2520%2520%2520height%253A%2520100%2525%253B%250A%2520%2520%257D%250A%253C%252Fstyle%253E%250A%253Cscript%253E%250A%2520%2520%2522use%2520strict%2522%253Bwindow.onload%253D()%253D%253E%257Blet%2520m%252Ca%253Ddocument.body%252Cr%253DgasPrice%252Cw%253D!1%253Bconst%2520L%253Dnew%2520THREE.Color(16731456)%252Cz%253Dnew%2520THREE.Color(1965840)%252CA%253D()%253D%253E%257Bconst%2520t%253DbaselineGasPrice%252BmaxDelta%252Co%253DMath.max(baselineGasPrice-maxDelta%252C0)%252Cd%253Dnew%2520THREE.Color(1940464)%253Breturn%2520gasPrice%253EbaselineGasPrice%253Fd.lerp(L%252C(gasPrice-baselineGasPrice)%252F(t-baselineGasPrice))%253AgasPrice%253CbaselineGasPrice%253Fd.lerp(z%252C1-(gasPrice-o)%252F(baselineGasPrice-o))%253Ad%257D%252CB%253Dt%253D%253E%2560%253C%253Fxml%2520version%253D%25221.0%2522%2520encoding%253D%2522UTF-8%2522%253F%253E%250A%253Csvg%2520version%253D%25221.1%2522%2520viewBox%253D%25220%25200%252024%252024%2522%2520xmlns%253D%2522http%253A%252F%252Fwww.w3.org%252F2000%252Fsvg%2522%253E%250A%253Cg%2520fill%253D%2522%2524%257Bt%257D%2522%253E%250A%253Cpath%2520d%253D%2522M22.25%252012c0-1.43-.88-2.67-2.19-3.34.46-1.39.2-2.9-.81-3.91s-2.52-1.27-3.91-.81c-.66-1.31-1.91-2.19-3.34-2.19s-2.67.88-3.33%25202.19c-1.4-.46-2.91-.2-3.92.81s-1.26%25202.52-.8%25203.91c-1.31.67-2.2%25201.91-2.2%25203.34s.89%25202.67%25202.2%25203.34c-.46%25201.39-.21%25202.9.8%25203.91s2.52%25201.26%25203.91.81c.67%25201.31%25201.91%25202.19%25203.34%25202.19s2.68-.88%25203.34-2.19c1.39.45%25202.9.2%25203.91-.81s1.27-2.52.81-3.91c1.31-.67%25202.19-1.91%25202.19-3.34zm-11.71%25204.2L6.8%252012.46l1.41-1.42%25202.26%25202.26%25204.8-5.23%25201.47%25201.36-6.2%25206.77z%2522%2520fill%253D%2522%25231d9bf0%2522%252F%253E%250A%253C%252Fg%253E%250A%253C%252Fsvg%253E%2560%252CD%253Dt%253D%253E%257Bconst%2520o%253Dnew%2520THREE.TextureLoader().load(%2560data%253Aimage%252Fsvg%252Bxml%252C%2524%257BencodeURIComponent(t)%257D%2560)%252Cd%253Dnew%2520THREE.MeshBasicMaterial(%257Btransparent%253A!0%252Copacity%253A.65%252Ccolor%253A16777147%252Cblending%253ATHREE.AdditiveBlending%252Cmap%253Ao%257D)%252Ce%253Dnew%2520THREE.PlaneGeometry(128%252C128)%253Breturn%257Btexture%253Ao%252Cmaterial%253Ad%252Cgeometry%253Ae%257D%257D%252Cf%253Ddocument.createElement(%2522input%2522)%253Bf.type%253D%2522checkbox%2522%252Cf.id%253D%2522liveCheckbox%2522%253Bconst%2520h%253Ddocument.createElement(%2522label%2522)%253Bh.htmlFor%253D%2522liveCheckbox%2522%252Ch.innerText%253D%2522Live%2520update%2522%253Bconst%2520c%253Ddocument.createElement(%2522span%2522)%253Bc.style.position%253D%2522absolute%2522%252Cc.style.bottom%253D%252210%2522%252Cc.style.left%253D%252210%2522%252Ch.style.color%253D%2522white%2522%252Ch.style.marginLeft%253D%252210px%2522%252Cc.appendChild(f)%252Cc.appendChild(h)%252Ca.appendChild(c)%252Cf.addEventListener(%2522change%2522%252Ct%253D%253E%257Bw%253Dt.target.checked%252Cw%2526%2526(x%253D0)%257D)%253Bconst%2520y%253Ddocument.createElement(%2522div%2522)%253By.style%253D%2522position%253A%2520absolute%253B%2520top%253A%252010%253B%2520right%253A%252010%253B%2520color%253A%2520white%2522%252Cy.innerText%253D%2560Gas%2520price%253A%2520%2524%257BgasPrice%257D%2520gwei%2560%252Ca.appendChild(y)%253Bconst%2520l%253Dt%253D%253E(t!%253D%253Dvoid%25200%2526%2526(m%253Dt%25252147483647)%253C%253D0%2526%2526(m%252B%253D2147483646)%252C((m%253D16807*m%25252147483647)-1)%252F2147483646)%253Bl(tokenId)%253Bconst%257Bwidth%253AC%252Cheight%253AE%257D%253Da.getBoundingClientRect()%253Blet%2520M%253DE%252F2%252Ci%253DE*2%252CR%253D0%253Bconst%2520s%253Dnew%2520THREE.PerspectiveCamera(80%252CC%252FE%252C1%252C3e3)%253Bs.position.z%253D1500%253Bfunction%2520O(t)%257Bt.isPrimary%2526%2526(R%253Dt.clientY-M)%257Dconst%2520n%253Dnew%2520THREE.Scene%253Bn.background%253Dnew%2520THREE.Color(0)%253Bconst%2520j%253Dnew%2520THREE.HemisphereLight(16777147%252C526368%252C1)%253Bn.add(j)%253Bconst%2520P%253Dnew%2520THREE.PointLight(16777147%252C1%252C1e3%252C0)%253BP.position.set(0%252C0%252C150)%252CP.lookAt(0%252C0%252C0)%252Cn.add(P)%253Bconst%2520p%253Dnew%2520THREE.WebGLRenderer(%257Bantialias%253A!0%257D)%253Bp.setPixelRatio(window.devicePixelRatio)%252Cp.setSize(C%252CE)%253Bconst%2520T%253Dnew%2520THREE.CylinderGeometry(50%252C100%252Ci%252C32%252C1%252C!0)%253BT.translate(0%252Ci%252F2%252C0)%253Bconst%2520I%253Dnew%2520THREE.MeshPhongMaterial(%257Bcolor%253AMath.ceil(16777215*l())%252Cside%253ATHREE.DoubleSide%252CflatShading%253A!0%257D)%252Cv%253Dnew%2520THREE.Mesh(T%252CI)%253Bv.position.set(0%252Ci%252F2%252C0)%252Cn.add(v)%253Blet%2520g%253D%255B%255D%253Bconst%2520b%253DD(B(%2522%25231d9bf0%2522))%253Bfunction%2520H()%257Bconst%2520t%253DDate.now()%252Co%253Dnew%2520THREE.Mesh(b.geometry%252Cb.material)%253Bo.delay%253DMath.floor(5e3*Math.random())%252Bt%252Co.position.set(10-30*Math.random()%252C2e5%252C10-30*Math.random())%252Cg.push(o)%252Cn.add(o)%257Dfor(let%2520t%253D0%253Bt%253Cr%253Bt%252B%252B)H()%253Bconst%2520%2524%253D%255B%255D%252CF%253D10%252BMath.ceil(10*l())%252CU%253Dnew%2520THREE.SphereGeometry(2%252C8%252C8)%252CG%253Dnew%2520THREE.MeshBasicMaterial%253BG.color.set(16777215)%253Bfor(let%2520t%253D0%253Bt%253CF%253Bt%252B%252B)%257Bconst%2520o%253Dnew%2520THREE.Mesh(U%252CG)%253Bo.position.set(1e3-2e3*l()%252C1e3-2e3*l()%252C1e3-2e3*l())%252C%2524.push(o)%252Cn.add(o)%257Dfunction%2520k()%257Bconst%257Bwidth%253At%252Cheight%253Ao%257D%253Da.getBoundingClientRect()%253BM%253Do%252F2%252Ci%253Do*2%252Cs.aspect%253Dt%252Fo%252Cs.updateProjectionMatrix()%252Cp.setSize(t%252Co)%252Cv.position.set(0%252Ci%252F2%252C0)%257Da.appendChild(p.domElement)%252Ca.style.touchAction%253D%2522none%2522%252Ca.addEventListener(%2522pointermove%2522%252CO)%252Cwindow.addEventListener(%2522resize%2522%252Ck)%252Ck()%253Blet%2520x%253D240%253Bfunction%2520S()%257Bif(requestAnimationFrame(S)%252Cb.material.color%253DA()%252Cw%2526%2526x--%253C0%2526%2526(x%253D240%252Cfetch(rpc%252C%257Bmethod%253A%2522POST%2522%252Cbody%253AJSON.stringify(%257Bjsonrpc%253A%25222.0%2522%252Cmethod%253A%2522eth_gasPrice%2522%252Cparams%253A%255B%255D%252Cid%253A1%257D)%257D).then(async%2520e%253D%253E%257Bconst%257Bresult%253Au%257D%253Dawait%2520e.json()%253BgasPrice%253DparseInt(u%252C16)%252F1e9%257D))%252CgasPrice!%253D%253Dr)%257Bif(gasPrice%253Er)for(let%2520e%253D0%253Be%253CgasPrice-r%253Be%252B%252B)H()%253Belse%257Blet%2520e%253Dr-gasPrice%253Bfor(const%2520u%2520of%2520g)if(u.done%257C%257C(u.done%253D!0%252Ce--)%252Ce%253C%253D0)break%257Dr%253DgasPrice%252Cy.innerText%253D%2560Gas%2520price%253A%2520%2524%257BgasPrice%257D%2520gwei%2560%257Ds.position.y%252B%253D.05*(200-R-s.position.y)%252Cn.rotation.y-%253D.005%252Cs.lookAt(n.position)%252Cp.render(n%252Cs)%253Bconst%2520t%253DDate.now()%252Co%253D.001*t%252Cd%253DMath.sin(o)%253Bfor(const%2520e%2520of%2520g)%257Bif(e.lookAt(s.position)%252Ce.delay)if(t%253Ee.delay)e.delay%253Dnull%252Ce.position.y%253Di%252F2%252B50%252B20*Math.random()%253Belse%2520continue%253Be.velocity%253De.velocity%257C%257Cnew%2520THREE.Vector3(0%252C-1%252C0)%252Ce.velocity.y-%253D.267%252Ce.position.add(e.velocity)%252Ce.position.y%253C-i%252F2%2526%2526(e.bounceCount%253Fe.bounceCount%253C3%253F(e.bounceCount%252B%252B%252Ce.velocity.y%253D-e.velocity.y*.2%252Ce.position.y%253D-i%252F2)%253Ae.done%253F(g.splice(g.indexOf(e)%252C1)%252Cn.remove(e))%253A(e.position.set(10-20*Math.random()%252C2e6%252C10-20*Math.random())%252Ce.bounceCount%253D0%252Ce.velocity.x%253D0%252Ce.velocity.y%253D-1%252Ce.velocity.z%253D0%252Ce.delay%253DMath.floor(5e3*Math.random())%252Bt)%253A(e.bounceCount%253D1%252Ce.velocity.x%253D8-16*Math.random()%252Ce.velocity.z%253D8-16*Math.random()%252Ce.velocity.y%253D-e.velocity.y*.2%252Ce.position.y%253D-i%252F2))%257D%257DS()%257D%253B%250A%250A%253C%252Fscript%253E"
      );
  }

  function scriptVars(
    uint256 tokenId,
    uint256 seed,
    uint24 gasPrice) internal view returns (string memory) {
    string memory tokenIdStr = GasLibs.uint2str(tokenId);
    string memory gasPriceGweiStr = GasLibs.gasPriceToStr(gasPrice);
    uint24 baselineGasPrice = getBaselineGasPrice(tokenId);
    return string.concat(
      compiler.SCRIPT_VAR("tokenId", tokenIdStr, true),
      compiler.SCRIPT_VAR("gasPrice", gasPriceGweiStr, true),
      compiler.SCRIPT_VAR("baselineGasPrice", baselineGasPrice == 0 ?  gasPriceGweiStr : GasLibs.gasPriceToStr(baselineGasPrice), true),
      compiler.SCRIPT_VAR("maxDelta", GasLibs.uint2str(GasLibs.getMaxDelta(seed)), true)
    );
  }

  function compileThreejs() internal view returns (string memory) {
    return compiler.compile9(
      threeAddresses[0],
      threeAddresses[1],
      threeAddresses[2],
      threeAddresses[3],
      threeAddresses[4],
      threeAddresses[5],
      threeAddresses[6],
      threeAddresses[7],
      threeAddresses[8]
    );
    
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IOnChainCheckRenderer_v2_Render {
  function render(uint256 tokenId, uint256 seed, uint24 gasPrice, bool isDarkMode, bool[80] memory isCheckRendered)
    external
    view
    returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;


interface IDataChunk {
  function data() external view returns (string memory);
}

interface IDataChunkCompiler {
  function BEGIN_JSON() external view returns (string memory);

  function END_JSON() external view returns (string memory);

  function HTML_HEAD() external view returns (string memory);

  function BEGIN_SCRIPT() external view returns (string memory);

  function END_SCRIPT() external view returns (string memory);

  function BEGIN_SCRIPT_DATA() external view returns (string memory);

  function END_SCRIPT_DATA() external view returns (string memory);

  function BEGIN_SCRIPT_DATA_COMPRESSED() external view returns (string memory);

  function END_SCRIPT_DATA_COMPRESSED() external view returns (string memory);

  function SCRIPT_VAR(
    string memory name,
    string memory value,
    bool omitQuotes
  ) external pure returns (string memory);

  function BEGIN_METADATA_VAR(string memory name, bool omitQuotes)
    external
    pure
    returns (string memory);

  function END_METADATA_VAR(bool omitQuotes)
    external
    pure
    returns (string memory);

  function compile2(address chunk1, address chunk2)
    external
    view
    returns (string memory);

  function compile3(
    address chunk1,
    address chunk2,
    address chunk3
  ) external returns (string memory);

  function compile4(
    address chunk1,
    address chunk2,
    address chunk3,
    address chunk4
  ) external view returns (string memory);

  function compile5(
    address chunk1,
    address chunk2,
    address chunk3,
    address chunk4,
    address chunk5
  ) external view returns (string memory);

  function compile6(
    address chunk1,
    address chunk2,
    address chunk3,
    address chunk4,
    address chunk5,
    address chunk6
  ) external view returns (string memory);

  function compile7(
    address chunk1,
    address chunk2,
    address chunk3,
    address chunk4,
    address chunk5,
    address chunk6,
    address chunk7
  ) external view returns (string memory);

  function compile8(
    address chunk1,
    address chunk2,
    address chunk3,
    address chunk4,
    address chunk5,
    address chunk6,
    address chunk7,
    address chunk8
  ) external view returns (string memory);

  function compile9(
    address chunk1,
    address chunk2,
    address chunk3,
    address chunk4,
    address chunk5,
    address chunk6,
    address chunk7,
    address chunk8,
    address chunk9
  ) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;


library GasLibs {
  uint256 constant MAX_MINT_GAS_PRICE = 1000000; // 1000 gwei mint would show all checks

  /**
   * @dev depending on seed, provide a max delta for color changes
   * 25% chance of a 50 delta
   * 25% chance of a 35 delta
   * 25% chance of a 25 delta
   * 15% chance of a 15 delta
   * 10% chance of a 5 delta 
   */
  function getMaxDelta(uint256 seed) public pure returns (uint8) {
    uint8 multiplier = 1;
    uint8 random = uint8((seed >> 128) % 100);
    if (random < 25) {
      multiplier = 50;
    } else if (random < 50) {
      multiplier = 35;
    } else if (random < 75) {
      multiplier = 25;
    } else if (random < 90) {
      multiplier = 15;
    } else {
      multiplier = 5;
    }
    return multiplier;
  }

  /**
   * @dev depending on seed, provide a boost to the gas price
   * 25% chance of a 1x multiplier
   * 25% chance of a 2x multiplier
   * 25% chance of a 3x multiplier
   * 15% chance of a 4x multiplier
   * 10% chance of a 5x multiplier 
   */
  function getGasPriceMultiplier(uint256 seed) public pure returns (uint8) {
    uint8 multiplier = 1;
    uint8 random = uint8(seed % 100);
    if (random < 25) {
      multiplier = 1;
    } else if (random < 50) {
      multiplier = 2;
    } else if (random < 75) {
      multiplier = 3;
    } else if (random < 90) {
      multiplier = 4;
    } else {
      multiplier = 5;
    }
    return multiplier;
  }

  function getNumberOfCheckMarks(bool[80] memory isCheckMarkRenderer) public pure returns (uint8) {
    uint8 count = 0;
    for (uint8 i = 0; i < 80; i++) {
      if (isCheckMarkRenderer[i]) {
        count++;
      }
    }
    return count;
  }


  /**
   * @dev For a given gas price (in 1/1000 gwei) and an index, returns whether a checkmark should be generated.
   * The index is the position of the checkmark in the 8 x 10 grid, starting from the top left.
   * For each index, generate a random number between 0 and 1000000. If the gas price is lower than the random number, do not generate a checkmark.
   * For an easy random number, let's use the seed and bit shift it to the right by the index
   */
  function checkmarkGenerates(uint256 seed, uint24 boostedGasPrice, uint8 index) internal pure returns (bool) {
    return boostedGasPrice > (uint24(seed >> index) % MAX_MINT_GAS_PRICE);
  }

  function getIsCheckRendered(uint256 seed, uint24 gasPrice) public pure returns (bool[80] memory) {
    bool[80] memory isCheckRendered;
    uint24 boostedGasPrice = gasPrice * getGasPriceMultiplier(seed);
    for (uint8 i = 0; i < 80; i++) {
      if (checkmarkGenerates(seed, boostedGasPrice, i)) {
        isCheckRendered[i] = true;
      }
    }
    return isCheckRendered;
  }


  function gasPriceToStr(uint24 gasPrice) public pure returns (string memory) {
    uint24 gasPriceLeftSideZero = gasPrice / 1000;
    uint24 gasPriceRightSideZero = gasPrice % 1000;
    return string.concat(
      uint2str(gasPriceLeftSideZero),
      ".",
      leftPad(uint2str(gasPriceRightSideZero), 3)
    );
  }


  // via https://stackoverflow.com/a/65707309
  function uint2str(uint256 _i)
    public
    pure
    returns (string memory _uintAsString)
  {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  function uint2hex(uint256 _i)
    public
    pure
    returns (string memory _uintAsHexString)
  {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 16;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 16) * 16));
      if (temp > 57) {
        temp += 7;
      }
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 16;
    }
    return string(bstr);
  }

  function leftPad(string memory str, uint256 length) public pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory paddedBytes = new bytes(length);
    for (uint256 i = 0; i < length; i++) {
      if (i < length - strBytes.length) {
        paddedBytes[i] = "0";
      } else {
        paddedBytes[i] = strBytes[i - (length - strBytes.length)];
      }
    }
    return string(paddedBytes);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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