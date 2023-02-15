/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

pragma solidity ^0.8.0;

contract Penduduk {
  // Mendefinisikan struktur data untuk penduduk
  struct DataPenduduk {
    string nama;
    string alamat;
    uint tanggalLahir;
    uint nomorIdentifikasi;
  }

  // Mendefinisikan mapping untuk data penduduk
  mapping (address => DataPenduduk) public dataPenduduk;

  // Event yang akan dipicu saat data penduduk ditambahkan atau diupdate
  event DataPendudukEvent(address indexed _address, string nama, string alamat, uint tanggalLahir, uint nomorIdentifikasi);

  // Fungsi untuk menambahkan atau memperbarui data penduduk
  function tambahDataPenduduk(string memory _nama, string memory _alamat, uint _tanggalLahir, uint _nomorIdentifikasi) public {
    // Memeriksa apakah data penduduk sudah ada
    if (bytes(dataPenduduk[msg.sender].nama).length == 0) {
      // Jika tidak ada, buat data penduduk baru
      DataPenduduk memory newDataPenduduk = DataPenduduk(_nama, _alamat, _tanggalLahir, _nomorIdentifikasi);
      dataPenduduk[msg.sender] = newDataPenduduk;
    } else {
      // Jika sudah ada, update data penduduk yang ada
      dataPenduduk[msg.sender].nama = _nama;
      dataPenduduk[msg.sender].alamat = _alamat;
      dataPenduduk[msg.sender].tanggalLahir = _tanggalLahir;
      dataPenduduk[msg.sender].nomorIdentifikasi = _nomorIdentifikasi;
    }
    // Picu event DataPendudukEvent
    emit DataPendudukEvent(msg.sender, _nama, _alamat, _tanggalLahir, _nomorIdentifikasi);
  }

  // Fungsi untuk mendapatkan data penduduk dari alamat tertentu
  function getDataPenduduk(address _address) public view returns (string memory, string memory, uint, uint) {
    return (dataPenduduk[_address].nama, dataPenduduk[_address].alamat, dataPenduduk[_address].tanggalLahir, dataPenduduk[_address].nomorIdentifikasi);
  }
}