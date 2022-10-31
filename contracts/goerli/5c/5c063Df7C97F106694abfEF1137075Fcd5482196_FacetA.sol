// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/** 
 * DiamondStorageを実装したライブラリを作成。
 * このライブラリは、Facets変数を格納する構造体と、文字列のハッシュからランダムな位置を指定し、コントラクトストレージに我々の構造体の位置を設定するdiamondStorage関数を含む。
 * bytes32の値を受け取り、上で定義したdiamondStorageを設定するsetDataAと、設定されたストレージから読み出すgetDataAの2つの関数を実装するコントラクトを作成。
 * Diamondスマートコントラクトをデプロイし、Facetを追加する流れは以下。
 * 
 * - DiamondInit.solの配置
 * - DiamondCutFacet.solをデプロイ
 * - DiamondLoupeFacet.solのデプロイ
 * - OwnershipFacet.solのデプロイ
 * - ダイヤモンドの配置(sol)
 * - FacetA.solの配置
 * - DiamondCut関数を呼び出してFacetAを追加
 */

library LibA {

  struct DiamondStorage {
      address owner;
      bytes32 dataA;
  }

  function diamondStorage() internal pure returns(DiamondStorage storage ds) {
    bytes32 storagePosition = keccak256("diamond.storage.LibA");
    assembly {
      ds.slot := storagePosition
    }
  }

}

contract FacetA {

  function setDataA(bytes32 _dataA) external {
    LibA.DiamondStorage storage ds = LibA.diamondStorage();
    ds.dataA = _dataA;
  }

  function getDataA() external view returns (bytes32) {
    return LibA.diamondStorage().dataA;
  }

}