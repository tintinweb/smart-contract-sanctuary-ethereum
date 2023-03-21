// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/* [開発]MemberNFT連携
 * TokenBankをMemberNFTと連携させる
 * NFTを持っていない場合、TokenBankで実装したファンクションの中核機能は実行できないようにする（tokenTransfer,deposit,withdraw）
 * 1．interfaceを定義する
 *    ・TokenBankからMemberNFTに接続する時に使用するファンクションのヘッダーだけを記載する
 * 2. MemberNFTにアクセスするためのオブジェクトを用意する
 *    ・Contract内に記述  MemberNFT public memberNFT;
 * 3. このTokenBankは、MemberNFTのアドレスをconstructorの引数に設定する
 *    ・特定のコントラクトとしか接続しない、という意思表示になる
 *    ・それをmemberNFTオブジェクトに設定する
 *  これで準備完了
 */
/*  [開発]制御実装
 * NFTを持っていない場合、銀行のtransfer、deposit、withdrawの機能を実行できないように制限をかける
 * Contractのownerはdeposit、withdrawをする必要がないので、制限しておく
 * 1. modifierを定義してこの2つの制限を実装する
 * 2. modifierを付与する
 * 
 * 総預入金額以上の移転は、ownerであってもできないように制限を掛ける
 * → ownerが利用者から預かっているトークンを含めて移転することができてしまうため、明示的に制限をする必要がある
 * ・transferファンクションに制限を掛ける
 */
interface MemberToken {
  // 【重要】複数のコントラクト間を連携させたり、複数のコントラクトを開発したりする場合、コントラクト名やインターフェース名が被らないように注意する
  // interfaceで名付けた"MemberNFT"という名前がcontract名と被っていて、testでエラーが出るので変更する
  // ERC-721のファンクションであるbalanceOfでNFTの所持数を確認する
  // （node_modules>@openzeppelin>token>ERC-721>ERC-721.solよりコピー）
  // public → external、virtual override → なし、{}なし
    function balanceOf(address owner) external view returns (uint256);
}



/// @dev TokenBank 個人間取引の実装

contract TokenBank {
  /// @dev interfaceのMemberTokenにアクセスするためのオブジェクト
  MemberToken public memberToken;

  /// @dev Tokenの名前
  string private _name;

  /// @dev Tokenのシンボル
  string private _symbol;

  /// @dev Tokenの総供給数(初期値を設定、定数constantを使用)
  uint256 constant _totalSupply = 1000;

  /// TokenBankにTokenを預けたり引き出したりする機能を作る
  /// 各アカウントアドレスはTokenを持つことができて、Bnakに預けることができる

  /// @dev TokenBankが預かっているTokenの総額
  uint256 private _bankTotalDeposit;

  /// @dev TokenBankのオーナー
  address public owner;

  /// @dev アカウントアドレス毎のToken残高
  mapping(address => uint256) private _balances;

  /// @dev TokenBankが預かっているToken残高
  mapping(address => uint256) private _tokenBankBalances;

  /// @dev Token移転時のイベント
  event TokenTransfer(
    address indexed from,
    address indexed to,
    uint256 amount
  );

  /// @dev Token預入時のイベント
  event TokenDeposit(
    address indexed from,
    uint256 amount
  );

  /// @dev Token引き出し時のイベント
  event TokenWithdraw(
    address indexed from,
    uint256 amount
  );

  // constructorの引数はmemory指定（受け取った引数を変更しなくても）
  // memberNFTと連携するためのアドレスを第三引数に追加設定する
  constructor (
    string memory name_,
    string memory symbol_,
    address nftContract_
    ) {
    _name = name_;
    _symbol = symbol_;
    owner = msg.sender;
    // 渡したアドレスのToken残高を返す
    _balances[owner] = _totalSupply;
    // MemberNFTにアクセスするためのオブジェクト
    memberToken = MemberToken(nftContract_);
  }

  /// @dev NFTメンバーのみ
  // msg.senderでトランザクションの発行者のNFT数が1以上の時
  modifier onlyMember() {
    require(memberToken.balanceOf(msg.sender) > 0, "not NFT member");
    _;
  }

  /// @dev オーナー以外
  modifier notOwner() {
    require(owner != msg.sender, "Owner cannot execute");
    _;
  }

  /* constructorで定義した内容を取得するファンクションを作成する
   * privateで定義されている変数・定数を、スマコン外からでも取得できるようにする
   */

  /// @dev Tokenの名前を返す
  function name() public view returns(string memory){
    return _name;
  }

  /// @dev Tokenのシンボルを返す
  function symbol() public view returns(string memory){
    return _symbol;
  }
  /// @dev Tokenの総供給数totalSupplyを返す
  // 定数を返す時は、pureを付与する
  function totalSupply() public pure returns(uint256){
    return _totalSupply;
  }

  /// @dev 指定アカウントアドレスのToken残高を返す
  function balanceOf(address account) public view returns(uint256) {
    return _balances[account];
  }

  // testディレクトリ直下にTokenBank.jsを作成

  /// @dev 個人間でトークンを移転する
  // transferファンクションを作成し、その中で_transferファンクションを実行させる2段階構造
  function transfer(address to, uint256 amount) public onlyMember {
    // 総預入金額以上の移転は、ownerであってもできないように制限を掛ける
    // ownerが持っているトークン数以上は移転できない条件
    if (owner == msg.sender) {
      require(_balances[owner] - _bankTotalDeposit >= amount, "Amounts greater than the total supply caccnot be transferred");
    }
    address from = msg.sender;
    _transfer(from, to, amount);
  }

  /// @dev 実際の移転処理
  function _transfer(address from, address to, uint256 amount) internal {
    // 宛先が0アドレスの場合、エラーとして失敗させる
    require(to != address(0), "Zero address cannot be specified for 'to'!");
    // 移転処理
    uint256 fromBalance = _balances[from];
    // 持っている金額よりも送る金額の方が多ければ、残高不足で失敗する処理
    require(fromBalance >= amount, "Insufficient balance!");

    // 送る側の所持トークン数から指定送金額を引く（残高の更新）
    _balances[from] = fromBalance - amount;
    // 受け取る側の所持トークン数に指定金額を足す
    _balances[to] += amount;
    // 移転のタイミングでイベントを発行する
    emit TokenTransfer(from, to, amount);
  }

  /* [開発]銀行への預入残高管理 */
  /// @dev TokenBankが預かっているTokenの総額を返す
  // uint256 private _bankTotalDeposit;
  function bankTotalDeposit() public view returns(uint256) {
    return _bankTotalDeposit;
  }
  /// @dev TokenBankが預かっている指定のアカウントアドレスのToken数を返す
  //  mapping(address => uint256) private _tokenBankBalances;
  function bankBalanceOf(address account) public view returns(uint256) {
    return _tokenBankBalances[account];
  }
  /// @dev Tokenを預ける
  function deposit(uint256 amount) public onlyMember notOwner {
    // 銀行ownerに指定したアドレスの、指定したTokenを移転する
    address from = msg.sender;
    address to = owner;

    _transfer(from, to, amount);
    // 銀行に預け入れたToken数の管理情報を更新する
    _tokenBankBalances[from] += amount;
    _bankTotalDeposit += amount;
    emit TokenDeposit(from, amount);
  } 
  /* [開発]銀行からのトークン引出 */
  /// @dev Tokenを預ける  
  function withdraw(uint256 amount) public onlyMember notOwner {
    address to = msg.sender;
    address from = owner;
    // 引き出す前の現在のTokenBalance残高を確認する
    uint256 toTokenBankBalance = _tokenBankBalances[to];
    require(toTokenBankBalance >= amount, "An amount greater than your tokenBank balance!");

    _transfer(from, to, amount);
    _tokenBankBalances[to] -= amount;
    _bankTotalDeposit -= amount;
    // 第一引数は、to
    emit TokenWithdraw(to, amount);
  }
} 
// テスト実装前に、"npx hardhat compile"でコンパイルを成功させておく