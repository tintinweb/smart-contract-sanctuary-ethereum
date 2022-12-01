// SPDX-License-Identifier: MIT

/*
██████╗ ██╗ ██████╗ ██╗████████╗ █████╗ ██╗     ██████╗ ███████╗██╗     ██╗ ██████╗
██╔══██╗██║██╔════╝ ██║╚══██╔══╝██╔══██╗██║     ██╔══██╗██╔════╝██║     ██║██╔════╝
██║  ██║██║██║  ███╗██║   ██║   ███████║██║     ██████╔╝█████╗  ██║     ██║██║     
██║  ██║██║██║   ██║██║   ██║   ██╔══██║██║     ██╔══██╗██╔══╝  ██║     ██║██║     
██████╔╝██║╚██████╔╝██║   ██║   ██║  ██║███████╗██║  ██║███████╗███████╗██║╚██████╗
╚═════╝ ╚═╝ ╚═════╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝ ╚═════╝                                                             

iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii!!iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii!i~~~i!iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii!!iiiiiiiii!>?fYYXf_!iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii!>-{<!!iii!!<}tjfjrtcr?iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii![tt(t1_>!>_tjf/\\fc/\Xf!iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii}vx]<~_}1-)0j\\\fnr/\v(<iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii>xn[+{}<>~]xm/\\jYY|\\z1!iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii>r1<>+(1~>+(vj\tcXvx\\z1!!<<!!iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiix\_<~}u)+{j/v/xJYnn\\Y1_jYCx+!iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii!!iiiiiiiiiiiiiiiiiiiYXf/trxnffjnOnYYvxfjc)~1CwZJ[!!iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii!!><<<<{?<>!iiiiiiiiiiiiiiii+XJfjjfunfxJ0CzuvcnjcJUYLmwCCc}!iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii!<1)fcuxj\fnj{iiiiiiiiiiiiiiii!|ccxffuxnLpLUYUc|+>nQZmZOdqOz{!iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii!i>+(rjffjf1{)fj)_iiiiiiiiiiiiiiiiil>{ncxvc0Zr?__-<l!i!+~nb0wqU]!iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii!!!iiiiiiiii!>]\rrf\\\/|)(\X|>!iiiiiiiiiiiiiiiiiiiil!{LCYX/l!!!!iiiii!]XqmO0J{iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii!i1/}iiiiiiii<{fjt\\\\//){\\rj-!iiiiiiiiiiiiiiiiiii!i_\cXn)~l!!iiiiiiiiiYdZZ}]>!iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii!!~|YYvYXiiiii!?vj/|\\|\j/{)/|/Y|~iiiiiiiiiiiiiiiiii!>[jXXj[>!!_)1<!l!iii>zZqC-!!iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii!i]rU0\xUZQiiii!}cf\\\\/f/v[)\/xccm)liiiiiiiiiiiiiiiii|xUX\_!!i!(CQOCj/}>ii>OqqJI!iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii!>1cCUv1nXOU_iiii!)Y\\\\\jv/}rtfcvfcZX[!iiiiiiiiiiiii!<tYXc)l!iiii}YwzwZOmu!i>jQqQ|>!iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii<(vLcrr{XzvOXliii!(Xcu/||jxnm[nfrzcncvbc!iiiiiiiiiiiii_tCvc]!iiii!fQ0QCpZwQt<<<iXbqq+<<<<<<<<<<<<<<<<>iiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii!]LUXCCv|?j/xOX!iii!uqccujfnxnb[xzccccccYOcliiiiiiiiiiil(Ztm]liiiii!_/Jp*0CCLCccccJQLLcccccccccccccccccZnliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiil}CJcczCz{)jccOX!iii!zdvccczzxxd}xrncccczvQQ)iiiiiiiiiii!)OtZ[!iiiiiiil]QonfnvvvvvvvuuuvvvvvvvvvvvvvvvrfqYliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii-xOcvzcUr}zzccZY!iii!/QCcccczufuZ\\nzccvr/j0p>iiiiiiiiii!(Z/m]liiiiiiiil?azQJzXXXXXXXXXXXXXXXXXXXXXXzXOzqXliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiIj0cc/fuzt}czzvZU!!iiil/kccccruJfhXtxznf/jvvQq>iiiiiiiiii!]cvJt+!ii!iiiil]azOYuYQQQQQQQQQQQQQQQQQQQQCcumzqYliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii]zQcccn)(\/zcr/nLz<<<<>jaXXXYjrCva(jvjfnzXXzOp~<<<<<<<<<<<>[qjw/i<<<<<<<>}oYmCj/nnnnnnnnnnnnnnnuunnur\um/QYliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii!cCvccczYr\jt\rvOkwcccccYLUUUUJYcJQXYXzUUUUUUCLcvccccccccccvzCYCXvcccccvvvz0JCJZZ/ttttttttttttt\}}\t((num|LYliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii!vOLCcccXQn-fLYvwbn?---[)111)1)))11)))))))11111))))))))))))))1)1))))))))){----\Zbnuuuuuuuuuuuuuuccunvvnum|LYliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiii!!iii!JaqqdzccY0pdmbZdbn??-tuvzccccccccccccccccccccccccccccccccccccccccccccczcvx]??jqbXXXXXXXXXXXXXXXXXXXXXzum|LYliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiii!]}!li!JabppQzczxvaQo*#bn?--Jc_<{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{+~rO]??jqqjjjjjjjjjjjjjjjjjjjjjn0q|LYliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiXpmY(>!xOpbwd0XcJZQhobabn?--UX--00000000000000000000000000000000000000000000Z{+u0]??jqpxnxxxxxxxxxxxxxxxxxxxvqq(LYliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiivwwdk<l;udmaXaQvZkXbwLpbn??-UX--Q0000000000000000000000000000000000000000000O1+n0]??jqbYYYYYYYYYYYYYYYYYYYYYY0q|LYliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiii!lfmdb/|+~xa*ZodJOkYanxwbn??-UX--Q0000000000000000000000000000000000000000000O1~n0]??jqbYUUUUYYYYYYYYYYUUUUUYcum|LYliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiii!i{zCOhoooq0w*odpmpoamoxxqbn?--UX--Q00000O0000000000000000000000000000000000000O1+n0]??jqpxnnnnnnnnnnnnnnnnnnnnnuw|LYliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiii<(ULJuJO1)1YZ0QOahdh*bZ*ZrQkn?--UX--Q0000Jz0000000000000000000000000000000000000O1+n0]??jqpxnnnnnnnnnnnnnnnnnnnnnuw|LYliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiil1oQt}{XZ}ll!!!!>)(YdadwdY/Qbu{{?UX-?Q0000Jv0O0000000OOOOOOOOOO0000O0000000000000O1+n0]?-jqduzXzzzzXzXXXXXXXXzXcnnuw|LYliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiil)OQzt?}/cZ|<!!!l!ll!-jQdd0qodznn}UX--Q00000OQvL000O0Qcuvt[uvvuUO0O0cJ000000000000O1+n0[{{xwkJCLLLLLLLLLLLLLLLLLCYnuw|LYliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiilfhvf\)1(\tJCUJv[iii!ll<|bqwhdznn}UX--Q000000QvL00Jj?\i,::,::::i+[x?_vO00000000000O1+n0}xucwduzzXXXXzXXXXXXXXXXXcnnuw|LYliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiilfbx\\t{[\\\jcXUCUUJt)]lixqk*dznn}UX--Q0000000O00c?":~;,,,,,,,,!_[x?+uO00000000000O1+n0[rucwdnnnnnnnnnnnnnnnnnnnnnnvmumYliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiilfhc\\\{[(\\|nzxtzzzJQCv\khwkdznn)JX--Q00000000000Juun]+_____juUOOOOcU000000000000O1+n0[rucwdnnnnnnnnnnnnnnnnnnnnunumXqXliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiil|Zz/\1)/|[|\tjnvccccvcY0oZOkdcnnn0z--Q000000000000OOO0000000OO00000O0000000000000O1+nZjnucwdnnnnnnnnnnnnnnnnnnnnunumzqXliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiii!)kt|\\\\({[1|xJzccccccvjmZdbcnnn0z?-Q0000000000000000000000000000000000000000000O1+nmvnncwdnnnnnnnnnnnnnnnnnnnnunumzqXliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiii!)h/\\((/fjvzQ0zYCnucczu[ZqkbXuuxOX?-Q0000000000000000000000000000000000000000000O1+nmunncwdnnnnnnnnnnnnnnnnnnnnunumzqXliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiii!}OJt|()\\\rucCwC|mCczzzur0obUYYjnYt-Q0000000000000000000000000000000000000000000O1+nmunncwdnnnnnnnnnnnnnnnnnnnnunumXqXliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiii!_0QYnftt\|nYYCkQ\mh0JJZqLczUYYUwY??0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOZ1+nmunncwdnnnnnnnnnnnnnnnnnnnnunvmf0Yliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiii)XO0JvuzQmOCZ0CtCbUCbjcbdXvvn0z?!--------------------------------------------?i+nmunncwdnnnnnnnnnnnnnnnnnnnnunvm(LYliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiii!!]|xqQmwOCXcc#tzbJptXQkdzunnLv{{)1)))))))))))))))))))))))))))))))))))))))))))1{r0unncwdnnnnnnnnnnnnnuuuunnnunumnmYliiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiii~)nXvtzCJCJJquJoOtY0Ymbznuufff(((((((((((((((((((((((((((((((((((((((((((((((tj/nuncwdnnnnnnnnnuuuuxfjuuununumXqXIiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiii!XC|p-li<>_xa?C#LrCZYYpbcnn/|ff\jrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrxxnnnvwdnnnnnnnun}?(x\l!-|xunnumzqL_!iiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiilYJ)b+!iiil+o)ZLxCf|\+XoJxxxxxxxnnnnnnnxxxxxxxxxxxxxxxxxxxxxxxxxxxxxrxnnnnnnnnnnnxrxXdbnnnnnnnux_{|jr|(+~\uunumJZwLc>iiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiilYwck~!ii!]JtLwunC!ll![/\\\\\|((((((((fmkqqqqqqqqqqqqqqqqqqqqqqwwqwqkqn)(((((((||/h0wwYnnnnnnnnnnuuuuuunnnnnnuwdcfQp<iiiii!!!iiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiii!xmQO1>!!l1h[b)vLIliii!ll!!!l~]]]]]]]]])dQJJJJJJJJJJJJJJJJJJJJJJJJUC#j][[]]]?]]_I>bUCYfjjjjjfjjfjjjjjjjjjjjjfrbv|jQq<i!!l>1v)~!iiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiii!\Zvm|?]?faxhuLkXX<!!!!!ii!+YkO0O00000QYCCCQZ00000000000000000ZOC0kxjrrXdpppZd0_<kXfnvvvvvvvvvvvvvvvvvvvvvvvzkUfrQqil_-\J0qr_!iiiiiii
iiiiiiiiiiiiiiiiiiiiiiiii!!~)zmuZv//tf\/\\/tfxjjr\-!!_QOvuuvnnnnnnnuvvvcYJJJJJJJJJJJJJJJYzvuYd1<>i>+_fjYXJb1ZUvvvccccccccccccccccccvvvvck0YXYLXzwbbmLw_!iiiiiiii
iiiiiiiiiiiiiiiiiiiiiiii>-\t}>><_+<<<<!lllli>_<>i+\t[d0zzzcjvzzzzzzzzzzzczzzzzzzzzzzzzzzzzzzzYhv)?~~>i!])(jjuc/{[~+~<~<~++~~~~~+++<?})jf|)/vXJaqdq0Y\<iiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiii!>m/!ll>>>><<>>>>>>>>>!iI(n][pYjtff/-|tttttttttttttttttttttttttttttttttfjUc\(}-czrvc<++\L0/!!_//-!!!-<!i!l!?}rYt[+-1nZhhmmc}>!!!iiiiiiiii
iiiiiiiiiiiiiiiiiiiiiii+vj-><<<<<<<<<<<<<<<<<<>xCYzvvLcrrxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxjjnLdQx\xuunf?[fYc{<[rzzn1i[jzc1li}jfzfi~1rpX|ft/~>!l!!!?<!iiiiiii
iiiiiiiiiiiiiiiiiiiiii!?b1++___>iii>>>iiiii!!!lLQ|/Xqavjzcccf//tttttttttttttfttttttffffffffttr**k0zCkQt))1\dhj~<1zCXj?l]Jz0x]i}Yffxx}i{rcq/IlIl?]/unxuo|!iiiiiii
iiiiiiiiiiiiiiiiiiiiii!-O/}]][]]]]]]]]]]]]]]]]?0mnxxxqCvcvvvx}_+llII;;II;;IIIllllllllllllllllitLUccvxt//fcZkZJzQ0Yk?I>(cJQn~lI\h)k\I{znCf+lli}vJCn\fczx_!iiiiiii
iiiiiiiiiiiiiiiiiiiiiiii+wt_]]]]]]]]]]]]]]]]]]]fLQcvtXqCjjrvUmJ{!!_runxnnnnu(_+!iiiiiiiiiiiiiil>|cYXcf/J0f<~tf0mQmJcxmhZZ*{__\C00Y{~zoQ*vjvYYUuxxnnUm-l!iiiiiiii
iiiiiiiiiiiiiiiiiiiiiiii>/j(}]~~~~~~~~~~~~~~~~~>/OZYc/~_n0Jr?~>l~rOJYznjfjjfnYJf<iiiiiiiiiiiiiiil>+]xLQOY1!!l;Cqz0wmUZmwMbCmpO0kdzOp0CboUvmkLj\pQYUx>!iiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiii!<{/txxxxxxxxxxxxxxxxxxftj/f|f}|Y+!!!ii>_tYJUUYvxxxvv\_i!iiiiiiiiiiiiiiii!!!~++>!iiilQQnp~~~CwLhjt-)QdYOk){LpJa}~<jmzzuYCJUui!iiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiii!!i++++++++++++++++++>ll!<+~[}>iiiiiii!l<(jffffff{>!!iiiiiiiiiiiiiiiiiiiii!!!iiiii!)zYuz~lzLXw-!!I[XC/k);]nvUn_!>]fjYYvfxQx~!iiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii!iiiiiiiii!!!iiiiiii!!i!!iiiiiiiiiii!llll!!l!iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiil}nnr~iir0xm_!il)w|k)!!!_|->ii!l!~|cCYuj~iiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii!i~liiii]/~iiiii_rp{!ii!!!iiiiiiil>+~~!iiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii!!iiiiii!!<>iiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii!iiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
*/

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract DigitalRelic is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  mapping(address => bool) private _approvedMarketplaces;

  uint256 public cost = 0 ether;
  uint256 public maxDigitalRelics = 2000;
  uint256 public txnMax = 1;
  uint256 public maxFreeMintEach = 1;
  uint256 public maxMintAmount = 1;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;

  bool public revealed = true;
  bool public paused = true;

  constructor(
  ) ERC721A("DigitalRelic", "DR") {
  }

  modifier DigitalRelicCompliance(uint256 _mintAmount) {
    require(!paused, "DigitalRelic season has not started.");
    require(_mintAmount > 0 && _mintAmount <= txnMax, "Maximum of 1 DigitalRelics per txn!");
    require(totalSupply() + _mintAmount <= maxDigitalRelics, "No DigitalRelics lefts!");
    require(
      _mintAmount > 0 && numberMinted(msg.sender) + _mintAmount <= maxMintAmount,
       "You may have minted max number of DigitalRelics!"
    );
    _;
  }

  modifier DigitalRelicPriceCompliance(uint256 _mintAmount) {
    uint256 realCost = 0;
    
    if (numberMinted(msg.sender) < maxFreeMintEach) {
      uint256 freeMintsLeft = maxFreeMintEach - numberMinted(msg.sender);
      realCost = cost * freeMintsLeft;
    }
   
    require(msg.value >= cost * _mintAmount - realCost, "Insufficient/incorrect funds.");
    _;
  }

  function Digitalized(uint256 _mintAmount) public payable DigitalRelicCompliance(_mintAmount) DigitalRelicPriceCompliance(_mintAmount) {
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxDigitalRelics, "Max supply exceeded!");
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setmaxFreeMintEach(uint256 _maxFreeMintEach) public onlyOwner {
    maxFreeMintEach = _maxFreeMintEach;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

   function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
    maxMintAmount = _maxMintAmount;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool withdrawFunds, ) = payable(owner()).call{value: address(this).balance}("");
    require(withdrawFunds);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function approve(address to, uint256 tokenId) public virtual override {
    require(_approvedMarketplaces[to], "Invalid marketplace");
    super.approve(to, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public virtual override {
    require(_approvedMarketplaces[operator], "Invalid marketplace");
    super.setApprovalForAll(operator, approved);
  }

  function setApprovedMarketplace(address market, bool approved) public onlyOwner {
    _approvedMarketplaces[market] = approved;
  }
}