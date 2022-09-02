//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface INamed {
    function name() external view returns(string memory);
}

interface AGData {
    function getData() external pure returns(string memory);
}

contract AudioGenesisHeader is AGData {
    string constant data = "data:application/html;base64,PCFET0NUWVBFIGh0bWw+PGh0bWwgbGFuZz0iZW4iPjxzdHlsZT4vKiBwbGF5IGJ1dHRvbiAqLyAjcGxheUJ0bjpjaGVja2Vke2FsaWduLXNlbGY6IHN0cmV0Y2g7IGJvcmRlcjogcmdiYSgxMjgsIDEyOCwgMTI4LCAwLjApOyBib3JkZXItcmFkaXVzOiAxMCU7IGJhY2tncm91bmQ6IHJnYmEoMjU1LCAyNTUsIDI1NSwgMC4wKTsgYmFja2dyb3VuZC1zaXplOiA4MCUgODAlOyBjdXJzb3I6IHBvaW50ZXI7IGNvbG9yOiByZ2JhKDEwOCwgMTA4LCAxMDgsIDAuMCk7fSNwbGF5QnRue2FwcGVhcmFuY2U6IG5vbmU7IHdpZHRoOiA5OCU7IGhlaWdodDogOTglOyBtYXJnaW46IDBweDsgcGFkZGluZzogMDsgYm9yZGVyLXJhZGl1czogMTAlOyBiYWNrZ3JvdW5kOiByZ2JhKDI1NSwgMjU1LCAyNTUsIDAuMCkgdXJsKCdkYXRhOmltYWdlL3N2Zyt4bWw7Y2hhcnNldD11dGY4LDxzdmcgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB2aWV3Qm94PSIwIDAgNDQ4IDUxMiI+PHBhdGggZD0iTTQyNC40IDIxNC43TDcyLjQgNi42QzQzLjgtMTAuMyAwIDYuMSAwIDQ3LjlWNDY0YzAgMzcuNSA0MC43IDYwLjEgNzIuNCA0MS4zbDM1Mi0yMDhjMzEuNC0xOC41IDMxLjUtNjQuMSAwLTgyLjZ6IiBmaWxsPSJ3aGl0ZSIvPjwvc3ZnPicpIG5vLXJlcGVhdCBjZW50ZXIgY2VudGVyOyBiYWNrZ3JvdW5kLXNpemU6IDgwJSA4MCU7IGN1cnNvcjogcG9pbnRlcjsgcG9zaXRpb246IGFic29sdXRlO30jdmlzdWFsaXplcntib3JkZXItcmFkaXVzOiA1JTsgd2lkdGg6IDEwMCU7IGhlaWdodDogMTAwJTsgbWFyZ2luOiAwcHg7IG92ZXJmbG93OiBoaWRkZW47IGRpc3BsYXk6IGJsb2NrO30ubGFiZWx7YmFja2dyb3VuZC1jb2xvcjogYmxhY2s7IGNvbG9yOiB3aGl0ZTsgZm9udC1mYW1pbHk6ICJBcmlhbCBCbGFjayI7IG1hcmdpbi1sZWZ0OiAyMHB4OyBwYWRkaW5nOiA1cHg7fSNtZXNzYWdle3Bvc2l0aW9uOiBhYnNvbHV0ZTsgdG9wOiA1JTsgd2lkdGg6IDk1JTsgZm9udC1zaXplOiBsYXJnZTsgZm9udC13ZWlnaHQ6IGJvbGRlcjsgdGV4dC1hbGlnbjogY2VudGVyOyBmb250LWZhbWlseTogIkx1Y2lkYSBDb25zb2xlIjsgY29sb3I6ICNmZmI3MDA7fTwvc3R5bGU+PGJvZHkgYmdjb2xvcj0iYmxhY2siPiA8ZGl2PiA8aW5wdXQgdHlwZT0iY2hlY2tib3giIGlkPSJwbGF5QnRuIi8+IDxkaXYgaWQ9Im1lc3NhZ2UiPiA8L2Rpdj48Y2FudmFzIGlkPSJ2aXN1YWxpemVyIiBjbGFzcz0idmlzdWFsaXplciI+IDwvY2FudmFzPiA8L2Rpdj48L2JvZHk+PHNjcmlwdD4KICAgIC8vIFJldmVyYkdlbiBDb3B5cmlnaHQgMjAxNCBBbGFuIGRlTGVzcGluYXNzZQogICAgLy8gTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CnZhciByZXZlcmJHZW49e307cmV2ZXJiR2VuLmdlbmVyYXRlUmV2ZXJiPWZ1bmN0aW9uKGEsail7Zm9yKHZhciBrPWEuYXVkaW9Db250ZXh0fHxuZXcgQXVkaW9Db250ZXh0LGM9YS5zYW1wbGVSYXRlfHw0NDEwMCxlPWEubnVtQ2hhbm5lbHN8fDIsbD0xLjUqYS5kZWNheVRpbWUsbT1NYXRoLnJvdW5kKGEuZGVjYXlUaW1lKmMpLGY9TWF0aC5yb3VuZChsKmMpLGc9TWF0aC5yb3VuZCgoYS5mYWRlSW5UaW1lfHwwKSpjKSxuPU1hdGgucG93KC4wMDEsMS9tKSxoPWsuY3JlYXRlQnVmZmVyKGUsZixjKSxkPTA7ZDxlO2QrKyl7Zm9yKHZhciBpPWguZ2V0Q2hhbm5lbERhdGEoZCksYj0wO2I8ZjtiKyspaVtiXT1yYW5kb21TYW1wbGUoKSpNYXRoLnBvdyhuLGIpO2Zvcih2YXIgYj0wO2I8ZztiKyspaVtiXSo9Yi9nfWFwcGx5R3JhZHVhbExvd3Bhc3MoaCxhLmxwRnJlcVN0YXJ0fHwwLGEubHBGcmVxRW5kfHwwLGEuZGVjYXlUaW1lLGopfSxyZXZlcmJHZW4uZ2VuZXJhdGVHcmFwaD1mdW5jdGlvbihkLGYsZSxnLGgpe3ZhciBhPWRvY3VtZW50LmNyZWF0ZUVsZW1lbnQoImNhbnZhcyIpO2Eud2lkdGg9ZixhLmhlaWdodD1lO3ZhciBiPWEuZ2V0Q29udGV4dCgiMmQiKTtiLmZpbGxTdHlsZT0iIzAwMCIsYi5maWxsUmVjdCgwLDAsYS53aWR0aCxhLmhlaWdodCksYi5maWxsU3R5bGU9IiNmZmYiO2Zvcih2YXIgaT1mL2QubGVuZ3RoLGo9ZS8oaC1nKSxjPTA7YzxkLmxlbmd0aDtjKyspYi5maWxsUmVjdChjKmksZS0oZFtjXS1nKSpqLDEsMSk7cmV0dXJuIGF9LHJldmVyYkdlbi5zYXZlV2F2RmlsZT1mdW5jdGlvbihpLHIsbCl7Zm9yKHZhciBtPWkuc2FtcGxlUmF0ZSxkPWkubnVtYmVyT2ZDaGFubmVscyxnPWdldEFsbENoYW5uZWxEYXRhKGkpLGU9Z1swXS5sZW5ndGgsaj0zMjc2NyxoPTAsYz0wO2M8ZDtjKyspZm9yKHZhciBiPTA7YjxlO2IrKyloPU1hdGgubWF4KGgsTWF0aC5hYnMoZ1tjXVtiXSkpO2lmKGgmJihqPTMyNzY3L2gpLGwpe2Zvcih2YXIgbj0wLGM9MDtjPGQ7YysrKWZvcih2YXIgYj0wO2I8ZTtiKyspTWF0aC5hYnMoTWF0aC5yb3VuZChqKmdbY11bYl0pKT5sJiYobj1iKTtlPW4rMX12YXIgbz0yKmQqZSxwPW8rNDQscT1uZXcgQXJyYXlCdWZmZXIocCksYT1uZXcgRGF0YVZpZXcocSk7YS5zZXRVaW50MzIoMCwxMTc5MDExNDEwLCEwKSxhLnNldFVpbnQzMig0LHAtOCwhMCksYS5zZXRVaW50MzIoOCwxMTYzMjgwNzI3LCEwKSxhLnNldFVpbnQzMigxMiw1NDQ1MDEwOTQsITApLGEuc2V0VWludDMyKDE2LDE2LCEwKSxhLnNldFVpbnQxNigyMCwxLCEwKSxhLnNldFVpbnQxNigyMixkLCEwKSxhLnNldFVpbnQzMigyNCxtLCEwKTt2YXIgaz0yKmQ7YS5zZXRVaW50MzIoMjgsbSprLCEwKSxhLnNldFVpbnQxNigzMixrLCEwKSxhLnNldFVpbnQxNigzNCwxNiwhMCksYS5zZXRVaW50MzIoMzYsMTYzNTAxNzA2MCwhMCksYS5zZXRVaW50MzIoNDAsbywhMCk7Zm9yKHZhciBiPTA7YjxlO2IrKylmb3IodmFyIGM9MDtjPGQ7YysrKWEuc2V0SW50MTYoNDQrYiprKzIqYyxNYXRoLnJvdW5kKGoqZ1tjXVtiXSksITApO3ZhciBzPW5ldyBCbG9iKFtxXSx7dHlwZToiYXVkaW8vd2F2In0pLHQ9d2luZG93LlVSTC5jcmVhdGVPYmplY3RVUkwocyksZj1kb2N1bWVudC5jcmVhdGVFbGVtZW50KCJhIik7Zi5ocmVmPXQsZi5kb3dubG9hZD1yLGYuc3R5bGUuZGlzcGxheT0ibm9uZSIsZG9jdW1lbnQuYm9keS5hcHBlbmRDaGlsZChmKSxmLmNsaWNrKCl9O3ZhciBhcHBseUdyYWR1YWxMb3dwYXNzPWZ1bmN0aW9uKGEsZCxlLGcsaCl7aWYoMD09ZCl7aChhKTtyZXR1cm59dmFyIGk9Z2V0QWxsQ2hhbm5lbERhdGEoYSksYz1uZXcgT2ZmbGluZUF1ZGlvQ29udGV4dChhLm51bWJlck9mQ2hhbm5lbHMsaVswXS5sZW5ndGgsYS5zYW1wbGVSYXRlKSxmPWMuY3JlYXRlQnVmZmVyU291cmNlKCk7Zi5idWZmZXI9YTt2YXIgYj1jLmNyZWF0ZUJpcXVhZEZpbHRlcigpO2Q9TWF0aC5taW4oZCxhLnNhbXBsZVJhdGUvMiksZT1NYXRoLm1pbihlLGEuc2FtcGxlUmF0ZS8yKSxiLnR5cGU9Imxvd3Bhc3MiLGIuUS52YWx1ZT0xZS00LGIuZnJlcXVlbmN5LnNldFZhbHVlQXRUaW1lKGQsMCksYi5mcmVxdWVuY3kubGluZWFyUmFtcFRvVmFsdWVBdFRpbWUoZSxnKSxmLmNvbm5lY3QoYiksYi5jb25uZWN0KGMuZGVzdGluYXRpb24pLGYuc3RhcnQoKSxjLm9uY29tcGxldGU9ZnVuY3Rpb24oYSl7aChhLnJlbmRlcmVkQnVmZmVyKX0sYy5zdGFydFJlbmRlcmluZygpLHdpbmRvdy5maWx0ZXJOb2RlPWJ9LGdldEFsbENoYW5uZWxEYXRhPWZ1bmN0aW9uKGIpe2Zvcih2YXIgYz1bXSxhPTA7YTxiLm51bWJlck9mQ2hhbm5lbHM7YSsrKWNbYV09Yi5nZXRDaGFubmVsRGF0YShhKTtyZXR1cm4gY30scmFuZG9tU2FtcGxlPWZ1bmN0aW9uKCl7cmV0dXJuIDIqTWF0aC5yYW5kb20oKS0xfQogICAgY29uc3QgdmVydGV4U2hhZGVyU3JjID0gYGF0dHJpYnV0ZSB2ZWMyIHA7dm9pZCBtYWluKHZvaWQpIHtnbF9Qb3NpdGlvbiA9IHZlYzQocCwgMCwgMSk7fWAK";

    function getData() external pure override returns (string memory) {
        return data;
    }
}

contract AudioGenesisFooter is AGData {
    string constant data = "CiAgICBjb25zdCBhdWRpb0N0eD1uZXcgQXVkaW9Db250ZXh0LGxvb2thaGVhZD0yNSxzY2hlZHVsZUFoZWFkVGltZT0uMTtsZXQgbmV4dE5vdGVUaW1lPTAscmV2ZXJiTm9kZT1hdWRpb0N0eC5jcmVhdGVDb252b2x2ZXIoKTt2YXIgcGFyYW1zPXtmYWRlSW5UaW1lOmZhZGVJblRpbWUsZGVjYXlUaW1lOmRlY2F5VGltZSxzYW1wbGVSYXRlOk51bWJlcig0OGUzKSxscEZyZXFTdGFydDpscEZyZXFTdGFydCxscEZyZXFFbmQ6bHBGcmVxRW5kLG51bUNoYW5uZWxzOjF9O3JldmVyYkdlbi5nZW5lcmF0ZVJldmVyYihwYXJhbXMsKGU9PntyZXZlcmJOb2RlLmJ1ZmZlcj1lfSkpO2NvbnN0IGJpcXVhZEZpbHRlcj1hdWRpb0N0eC5jcmVhdGVCaXF1YWRGaWx0ZXIoKTtiaXF1YWRGaWx0ZXIudHlwZT1maWx0ZXJUeXBlLGJpcXVhZEZpbHRlci5mcmVxdWVuY3kuc2V0VmFsdWVBdFRpbWUoZmlsdGVyRnJlcXVlbmN5LDApLGJpcXVhZEZpbHRlci5nYWluLnNldFZhbHVlQXRUaW1lKGZpbHRlckdhaW4sMCksYmlxdWFkRmlsdGVyLlEuc2V0VmFsdWVBdFRpbWUoZmlsdGVyUSwwKTtjb25zdCBjb21wcmVzc29yPWF1ZGlvQ3R4LmNyZWF0ZUR5bmFtaWNzQ29tcHJlc3NvcigpO2NvbXByZXNzb3IudGhyZXNob2xkLnNldFZhbHVlQXRUaW1lKC03NSxhdWRpb0N0eC5jdXJyZW50VGltZSksY29tcHJlc3Nvci5rbmVlLnNldFZhbHVlQXRUaW1lKDQwLGF1ZGlvQ3R4LmN1cnJlbnRUaW1lKSxjb21wcmVzc29yLnJhdGlvLnNldFZhbHVlQXRUaW1lKDUsYXVkaW9DdHguY3VycmVudFRpbWUpLGNvbXByZXNzb3IuYXR0YWNrLnNldFZhbHVlQXRUaW1lKC4wMDUsYXVkaW9DdHguY3VycmVudFRpbWUpLGNvbXByZXNzb3IucmVsZWFzZS5zZXRWYWx1ZUF0VGltZSguMjUsYXVkaW9DdHguY3VycmVudFRpbWUpO2NvbnN0IGFuYWx5c2VyPWF1ZGlvQ3R4LmNyZWF0ZUFuYWx5c2VyKCk7YmlxdWFkRmlsdGVyLmNvbm5lY3QocmV2ZXJiTm9kZSkscmV2ZXJiTm9kZS5jb25uZWN0KGNvbXByZXNzb3IpLGNvbXByZXNzb3IuY29ubmVjdChhbmFseXNlciksYW5hbHlzZXIuY29ubmVjdChhdWRpb0N0eC5kZXN0aW5hdGlvbik7Y29uc3Qgc3BlY3RydW09bmV3IFVpbnQ4QXJyYXkoYW5hbHlzZXIuZnJlcXVlbmN5QmluQ291bnQpOyFmdW5jdGlvbiBlKCl7cmVxdWVzdEFuaW1hdGlvbkZyYW1lKGUpLGFuYWx5c2VyLmdldEJ5dGVGcmVxdWVuY3lEYXRhKHNwZWN0cnVtKX0oKTt2YXIgbmV4dFRpbWU9MDtmdW5jdGlvbiBwbGF5UHVsc2UoZSx0LGksbixhKXtjb25zdCByPW5ldyBPc2NpbGxhdG9yTm9kZShhdWRpb0N0eCx7dHlwZToic2luZSIsZnJlcXVlbmN5OmV9KSxzPW5ldyBHYWluTm9kZShhdWRpb0N0eCx7dmFsdWU6YX0pOyh0PjExZTN8fCErdCkmJih0PTExZTMpO2NvbnN0IG89bmV3IE9zY2lsbGF0b3JOb2RlKGF1ZGlvQ3R4LHt0eXBlOiJzaW5lIixmcmVxdWVuY3k6dH0pO28uY29ubmVjdChzLmdhaW4pLHIuY29ubmVjdChzKS5jb25uZWN0KGJpcXVhZEZpbHRlciksby5zdGFydCgpLHIuc3RhcnQobiksci5zdG9wKG4raSl9ZnVuY3Rpb24gc2NoZWR1bGVOb3RlKGUsdCxpLG4sYSl7cGxheVB1bHNlKGUsdCxpLG4sYSl9Y29uc3QgT3BlblNlYT0iMHg5ZDlhZjhlMzhkNjZjNjJlMmMxMmYwMjI1MjQ5ZmQ5ZDcyMWM1NGI4M2Y0OGQ5MzUyYzk3YzZjYWNkY2I2ZjMxIixYMlkyPSIweDNjYmI2M2YxNDQ4NDBlNWIxYjBhMzhhN2MxOTIxMWQyZTg5ZGU0ZDdjNWZhZjhiMmQzYzE3NzZjMzAyZDFkMzMiLExvb2tzUmFyZT0iMHg5NWZiNjIwNWUyM2ZmNmJkYTE2YTJkMWRiYTU2YjlhZDdjNzgzZjY3Yzk2ZmExNDk3ODUwNTJmNDc2OTZmMmJlIixUb2tlbj0iMHhkZGYyNTJhZDFiZTJjODliNjljMmIwNjhmYzM3OGRhYTk1MmJhN2YxNjNjNGExMTYyOGY1NWE0ZGY1MjNiM2VmIixFUkMxMTU1PSIweGMzZDU4MTY4YzVhZTczOTc3MzFkMDYzZDViYmYzZDY1Nzg1NDQyNzM0M2Y0YzA4MzI0MGY3YWFjYWEyZDBmNjIiLFN1ZG9Td2FwPSIweGYwNjE4MGZkYmU5NWU1MTkzZGY0ZGNkMTM1MjcyNmIxZjA0Y2I1ODU5OWNlNTg1NTJjYzk1MjQ0N2FmMmZmYmIiO2NsYXNzIE9yZGVyRnVsZmlsbGVke29yZGVySGFzaDtvZmZlcmVyO3pvbmU7c3BlbnRJdGVtcztyZWNlaXZlZEl0ZW1zO2N1cnJlbmN5O2Ftb3VudDtjb2xsZWN0aW9uO3JlY2lwaWVudDtjb25zdHJ1Y3RvcihlKXtzd2l0Y2goZS50b3BpY3NbMF0pe2Nhc2UgT3BlblNlYTp0aGlzLnBhcnNlT3BlblNlYShlKTticmVhaztjYXNlIFgyWTI6dGhpcy5wYXJzZVgyWTIoZSk7YnJlYWs7Y2FzZSBMb29rc1JhcmU6dGhpcy5wYXJzZUxvb2tzUmFyZShlKTticmVhaztjYXNlIFRva2VuOnRoaXMucGFyc2VUb2tlbihlKTticmVhaztjYXNlIEVSQzExNTU6dGhpcy5wYXJzZUVSQzExNTUoZSk7YnJlYWs7Y2FzZSBTdWRvU3dhcDp0aGlzLnBhcnNlU3Vkb1N3YXAoZSl9fXBhcnNlVG9rZW49ZnVuY3Rpb24oZSl7dGhpcy5jb2xsZWN0aW9uPWUuYWRkcmVzcyx0aGlzLm9mZmVyZXI9ZS50b3BpY3NbMV0sdGhpcy5yZWNpcGllbnQ9ZS50b3BpY3NbMl0sdGhpcy5jdXJyZW5jeT0wLHRoaXMuYW1vdW50PTEwKioxNX07cGFyc2VFUkMxMTU1PWZ1bmN0aW9uKGUpe3RoaXMuY29sbGVjdGlvbj1lLmFkZHJlc3MsdGhpcy5vZmZlcmVyPWUudG9waWNzWzJdLHRoaXMucmVjaXBpZW50PWUudG9waWNzWzNdLHRoaXMuY3VycmVuY3k9MCx0aGlzLmFtb3VudD0xMCoqMTV9O3BhcnNlU3Vkb1N3YXA9ZnVuY3Rpb24oZSl7bGV0IHQ9ZS5kYXRhO3RoaXMuY29sbGVjdGlvbj1lLmFkZHJlc3MsdGhpcy5yZWNpcGllbnQ9ZS50b3BpY3NbMV0sdGhpcy5jdXJyZW5jeT0xLHRoaXMuYW1vdW50PStnZXRGaWVsZCh0LDAsNjQpLzEwKioxOH07cGFyc2VMb29rc1JhcmU9ZnVuY3Rpb24oZSl7bGV0IHQ9ZS5kYXRhO3RoaXMuY29sbGVjdGlvbj1nZXRGaWVsZCh0LDMsNDApLHRoaXMucmVjaXBpZW50PWUudG9waWNzWzFdLHRoaXMub2ZmZXJlcj1lLnRvcGljc1syXSx0aGlzLmN1cnJlbmN5PStnZXRGaWVsZCh0LDIsNDApLHRoaXMuYW1vdW50PStnZXRGaWVsZCh0LDYsNjQpLzEwKioxOH07cGFyc2VYMlkyPWZ1bmN0aW9uKGUpe2xldCB0PWUuZGF0YTt0aGlzLmNvbGxlY3Rpb249Z2V0RmllbGQodCwwLDQwKSx0aGlzLnJlY2lwaWVudD1nZXRGaWVsZCh0LDEsNDApLHRoaXMuY3VycmVuY3k9K2dldEZpZWxkKHQsNyw0MCksdGhpcy5hbW91bnQ9K2dldEZpZWxkKHQsMTIsNjQpLzEwKioxOH07cGFyc2VPcGVuU2VhPWZ1bmN0aW9uKGUpe2xldCB0PWUudG9waWNzLGk9ZS5kYXRhO3RoaXMub3JkZXJIYXNoPWdldEZpZWxkKGksMCw2NCksdGhpcy5vZmZlcmVyPWdldEZpZWxkKHRbMV0sMCw0MCksdGhpcy56b25lPWdldEZpZWxkKHRbMl0sMCw0MCksdGhpcy5yZWNpcGllbnQ9Z2V0RmllbGQoaSwxLDQwKTt2YXIgbj00LGE9K2dldEZpZWxkKGksbisrLDgpO3RoaXMuc3BlbnRJdGVtcz1bXTtmb3IodmFyIHI9MDtyPGE7cisrKXRoaXMuc3BlbnRJdGVtcy5wdXNoKHtpdGVtVHlwZTorZ2V0RmllbGQoaSxuKyssNCksdG9rZW46Z2V0RmllbGQoaSxuKyssNDApLGlkZW50aWZpZXI6Z2V0RmllbGQoaSxuKyssNjQpLGFtb3VudDorZ2V0RmllbGQoaSxuKyssNjQpfSk7dGhpcy5zcGVudEl0ZW1zWzBdLml0ZW1UeXBlPDI/KHRoaXMuY3VycmVuY3k9K3RoaXMuc3BlbnRJdGVtc1swXS50b2tlbix0aGlzLmFtb3VudD0rdGhpcy5zcGVudEl0ZW1zWzBdLmFtb3VudC8xMCoqMTgpOnRoaXMuY29sbGVjdGlvbj10aGlzLnNwZW50SXRlbXNbMF0udG9rZW4sdGhpcy5yZWNlaXZlZEl0ZW1zPVtdLGE9K2dldEZpZWxkKGksbisrLDgpO2ZvcihyPTA7cjxhO3IrKyl0aGlzLnJlY2VpdmVkSXRlbXMucHVzaCh7aXRlbVR5cGU6Z2V0RmllbGQoaSxuKyssNCksdG9rZW46Z2V0RmllbGQoaSxuKyssNDApLGlkZW50aWZpZXI6Z2V0RmllbGQoaSxuKyssNjQpLGFtb3VudDpnZXRGaWVsZChpLG4rKyw2NCkscmVjaXBpZW50OmdldEZpZWxkKGksbisrLDQwKX0pO3RoaXMucmVjZWl2ZWRJdGVtc1swXS5pdGVtVHlwZTwyPyh0aGlzLmN1cnJlbmN5PSt0aGlzLnNwZW50SXRlbXNbMF0udG9rZW4sdGhpcy5hbW91bnQ9K3RoaXMuc3BlbnRJdGVtc1swXS5hbW91bnQvMTAqKjE4KTp0aGlzLmNvbGxlY3Rpb249dGhpcy5yZWNlaXZlZEl0ZW1zWzBdLnRva2VufX1mdW5jdGlvbiBnZXRGaWVsZChlLHQsaSl7bGV0IG49Mis2NCp0KzY0LWksYT1uK2k7cmV0dXJuIjB4IitlLnNsaWNlKG4sYSl9bGV0IHRpbWVySUQsdGltZXJJRDIsbGFzdFJlY2VpdmVkVGltZXN0YW1wPTAsdHhMaXN0PVtdO2Z1bmN0aW9uIHNjaGVkdWxlcigpe2ZvcigwPT10eExpc3QubGVuZ3RoJiZkb2N1bWVudC5nZXRFbGVtZW50QnlJZCgibWVzc2FnZSIpLnRleHRDb250ZW50Lmxlbmd0aDwyP2RvY3VtZW50LmdldEVsZW1lbnRCeUlkKCJtZXNzYWdlIikudGV4dENvbnRlbnQ9IkFXQUlUSU5HIFRSQU5TQUNUSU9OUy4uLiI6dHhMaXN0Lmxlbmd0aD4wJiYoZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQoIm1lc3NhZ2UiKS50ZXh0Q29udGVudD0iIik7bmV4dE5vdGVUaW1lPGF1ZGlvQ3R4LmN1cnJlbnRUaW1lKy4xOyl7dmFyIGU9LjEyNTtpZih0eExpc3QubGVuZ3RoPjApe2xldCB0PXR4TGlzdFswXSxpPStsb3dQdWxzZSsgK3B1bHNlU3RlcCooMSsgK3QuY29sbGVjdGlvbiVwdWxzZU1vZCksbj1pLygxKyArdC5yZWNpcGllbnQlbGZvTW9kKTswPT10LmN1cnJlbmN5Py50b2tlbiYmKGkrPTEpO2xldCBhPSg3K01hdGgubG9nKE1hdGgubWF4KDFlLTUsdC5jdXJyZW5jeT8uYW1vdW50LzEwKioxOCkpKS84LHI9dGltZU1vZC8yKipNYXRoLnJvdW5kKE1hdGgubG9nKHR4TGlzdC5sZW5ndGgpKTtzY2hlZHVsZU5vdGUoaSxuLE1hdGgubWF4KHIsZSksbmV4dE5vdGVUaW1lLGEpLGU9cix0eExpc3Quc2hpZnQoKX1uZXh0Tm90ZVRpbWUrPWV9dGltZXJJRD1zZXRUaW1lb3V0KHNjaGVkdWxlciwyNSl9ZnVuY3Rpb24gdGltZW91dChlKXtyZXR1cm4gbmV3IFByb21pc2UoKHQ9PnNldFRpbWVvdXQodCxlKSkpfW5leHROb3RlVGltZT1hdWRpb0N0eC5jdXJyZW50VGltZTtjb25zdCBwbGF5QnV0dG9uPWRvY3VtZW50LnF1ZXJ5U2VsZWN0b3IoIiNwbGF5QnRuIik7bGV0IGlzUGxheWluZz0hMTtwbGF5QnV0dG9uLmFkZEV2ZW50TGlzdGVuZXIoImNsaWNrIiwoZT0+e2lzUGxheWluZz0haXNQbGF5aW5nLGlzUGxheWluZz8oZGVsZXRlIHR4TGlzdCx0eExpc3Q9W10sInN1c3BlbmRlZCI9PT1hdWRpb0N0eC5zdGF0ZSYmYXVkaW9DdHgucmVzdW1lKCksbmV4dE5vdGVUaW1lPWF1ZGlvQ3R4LmN1cnJlbnRUaW1lLHNjaGVkdWxlcigpLGUudGFyZ2V0LmRhdGFzZXQucGxheWluZz0idHJ1ZSIsc3RhcnRMaXN0ZW5pbmcoKSk6KGRlbGV0ZSB0eExpc3QsdHhMaXN0PVtdLGF1ZGlvQ3R4LnN1c3BlbmQoKSx3aW5kb3cuY2xlYXJUaW1lb3V0KHRpbWVySUQpLHdpbmRvdy5jbGVhclRpbWVvdXQodGltZXJJRDIpLGUudGFyZ2V0LmRhdGFzZXQucGxheWluZz0iZmFsc2UiLGRvY3VtZW50LmdldEVsZW1lbnRCeUlkKCJtZXNzYWdlIikudGV4dENvbnRlbnQ9IiIpfSkpO2xldCBtaW5CbG9jaz0wO2FzeW5jIGZ1bmN0aW9uIHZpc3VhbGl6ZSgpe2ZyYWdtZW50U2hhZGVyU3JjP2F3YWl0IHZpc3VhbGl6ZTNEKCk6YXdhaXQgdmlzdWFsaXplMkQoKX1hc3luYyBmdW5jdGlvbiB2aXN1YWxpemUzRCgpe2NvbnN0IGU9ZG9jdW1lbnQucXVlcnlTZWxlY3RvcigiLnZpc3VhbGl6ZXIiKSx0PWUuZ2V0Q29udGV4dCgid2ViZ2wyIiksaT1mdW5jdGlvbihlLHQsaSl7Y29uc3Qgbj1lLmNyZWF0ZVNoYWRlcihlLlZFUlRFWF9TSEFERVIpO2lmKGUuc2hhZGVyU291cmNlKG4sdCksZS5jb21waWxlU2hhZGVyKG4pLCFlLmdldFNoYWRlclBhcmFtZXRlcihuLGUuQ09NUElMRV9TVEFUVVMpKXRocm93IG5ldyBFcnJvcihlLmdldFNoYWRlckluZm9Mb2cobikpO2NvbnN0IGE9ZS5jcmVhdGVTaGFkZXIoZS5GUkFHTUVOVF9TSEFERVIpO2lmKGUuc2hhZGVyU291cmNlKGEsaSksZS5jb21waWxlU2hhZGVyKGEpLCFlLmdldFNoYWRlclBhcmFtZXRlcihhLGUuQ09NUElMRV9TVEFUVVMpKXRocm93IG5ldyBFcnJvcihlLmdldFNoYWRlckluZm9Mb2coYSkpO2NvbnN0IHI9ZS5jcmVhdGVQcm9ncmFtKCk7cmV0dXJuIGUuYXR0YWNoU2hhZGVyKHIsbiksZS5hdHRhY2hTaGFkZXIocixhKSxlLmxpbmtQcm9ncmFtKHIpLGUudXNlUHJvZ3JhbShyKSxyfSh0LHZlcnRleFNoYWRlclNyYyxmcmFnbWVudFNoYWRlclNyYyksbj10LmdldEF0dHJpYkxvY2F0aW9uKGksInAiKTt0LmVuYWJsZVZlcnRleEF0dHJpYkFycmF5KG4pO2NvbnN0IGE9dC5nZXRVbmlmb3JtTG9jYXRpb24oaSwicyIpO3QudW5pZm9ybTFmKGEsYXVkaW9DdHguY3VycmVudFRpbWUpO2NvbnN0IHI9dC5nZXRVbmlmb3JtTG9jYXRpb24oaSwiciIpO3QudW5pZm9ybTJmKHIsZS53aWR0aCxlLmhlaWdodCk7Y29uc3Qgcz1uZXcgVWludDhBcnJheSg0KnNwZWN0cnVtLmxlbmd0aCk7IWZ1bmN0aW9uKGUpe2NvbnN0IHQ9ZS5jcmVhdGVUZXh0dXJlKCk7ZS5iaW5kVGV4dHVyZShlLlRFWFRVUkVfMkQsdCksZS50ZXhQYXJhbWV0ZXJpKGUuVEVYVFVSRV8yRCxlLlRFWFRVUkVfTUlOX0ZJTFRFUixlLkxJTkVBUiksZS50ZXhQYXJhbWV0ZXJpKGUuVEVYVFVSRV8yRCxlLlRFWFRVUkVfV1JBUF9TLGUuQ0xBTVBfVE9fRURHRSksZS50ZXhQYXJhbWV0ZXJpKGUuVEVYVFVSRV8yRCxlLlRFWFRVUkVfV1JBUF9ULGUuQ0xBTVBfVE9fRURHRSl9KHQpOyFmdW5jdGlvbihlKXtjb25zdCB0PWUuY3JlYXRlQnVmZmVyKCk7ZS5iaW5kQnVmZmVyKGUuQVJSQVlfQlVGRkVSLHQpO2NvbnN0IGk9bmV3IEZsb2F0MzJBcnJheShbLTEsLTEsMSwtMSwtMSwxLDEsMV0pO2UuYnVmZmVyRGF0YShlLkFSUkFZX0JVRkZFUixpLGUuU1RBVElDX0RSQVcpLGUudmVydGV4QXR0cmliUG9pbnRlcigwLDIsZS5GTE9BVCwhMSwwLDApfSh0KSxmdW5jdGlvbiBuKCl7ZS53aWR0aD13aW5kb3cuaW5uZXJXaWR0aCxlLmhlaWdodD13aW5kb3cuaW5uZXJIZWlnaHQsdC52aWV3cG9ydCgwLDAsZS53aWR0aCxlLmhlaWdodCkscmVxdWVzdEFuaW1hdGlvbkZyYW1lKG4pO2NvbnN0IHI9dC5nZXRVbmlmb3JtTG9jYXRpb24oaSwiciIpO3QudW5pZm9ybTJmKHIsZS53aWR0aCxlLmhlaWdodCksdC51bmlmb3JtMWYoYSxhdWRpb0N0eC5jdXJyZW50VGltZSksZnVuY3Rpb24oZSx0LGkpe2ZvcihsZXQgZT0wO2U8dC5sZW5ndGg7ZSsrKWlbNCplKzBdPXRbZV0saVs0KmUrMV09dFtlXSxpWzQqZSsyXT10W2VdLGlbNCplKzNdPTI1NTtlLnRleEltYWdlMkQoZS5URVhUVVJFXzJELDAsZS5SR0JBLHQubGVuZ3RoLDEsMCxlLlJHQkEsZS5VTlNJR05FRF9CWVRFLGkpfSh0LHNwZWN0cnVtLHMpLGZ1bmN0aW9uKGUpe2UuZHJhd0FycmF5cyhlLlRSSUFOR0xFX1NUUklQLDAsNCl9KHQpfSgpfWFzeW5jIGZ1bmN0aW9uIHZpc3VhbGl6ZTJEKCl7dmFyIGU9ZG9jdW1lbnQucXVlcnlTZWxlY3RvcigiLnZpc3VhbGl6ZXIiKSx0PWUuZ2V0Q29udGV4dCgiMmQiKTt0LmNsZWFyUmVjdCgwLDAsaSxuKTt2YXIgaSxuO2lmKGUuc2V0QXR0cmlidXRlKCJ3aWR0aCIsNjQwKSxpPXdpbmRvdy5pbm5lcldpZHRoLG49d2luZG93LmlubmVySGVpZ2h0LGUud2lkdGg9aSxlLmhlaWdodD1uLGUuc2V0QXR0cmlidXRlKCJ3aWR0aCIsaSksMD09bmV4dFRpbWUmJihuZXh0VGltZT1hdWRpb0N0eC5jdXJyZW50VGltZSksIk9zY2lsbG9zY29wZSI9PXZpc3VhbGl6ZXIpe2FuYWx5c2VyLmZmdFNpemU9MjA0ODt2YXIgYT1hbmFseXNlci5mZnRTaXplLHI9bmV3IEZsb2F0MzJBcnJheShhKTthc3luYyBmdW5jdGlvbiBzKCl7bGV0IG89dGltZW91dCgzMyk7YW5hbHlzZXIuZ2V0RmxvYXRUaW1lRG9tYWluRGF0YShyKSxpPXdpbmRvdy5pbm5lcldpZHRoLG49d2luZG93LmlubmVySGVpZ2h0LGUud2lkdGg9aSxlLmhlaWdodD1uLGUuc2V0QXR0cmlidXRlKCJ3aWR0aCIsaSksdC5maWxsU3R5bGU9InJnYigwLCA4MCwgMCkiLHQuZmlsbFJlY3QoMCwwLGksbiksdC5saW5lV2lkdGg9MSx0LnN0cm9rZVN0eWxlPSJyZ2IoODAsIDI1NSwgODApIix0LmJlZ2luUGF0aCgpO2Zvcih2YXIgYz0xKmkvYSxsPTAsZD0wO2Q8YTtkKyspe3ZhciB1PTEwMCpyW2RdLG09bi8yK3U7MD09PWQ/dC5tb3ZlVG8obCxtKTp0LmxpbmVUbyhsLG0pLGwrPWN9dC5saW5lVG8oaSxuLzIpLHQuc3Ryb2tlKCksYXdhaXQgbyxyZXF1ZXN0QW5pbWF0aW9uRnJhbWUocyl9dC5jbGVhclJlY3QoMCwwLGksbikscygpfWVsc2UgaWYoIkZyZXF1ZW5jeSBCYXJzIj09dmlzdWFsaXplcil7YW5hbHlzZXIuZmZ0U2l6ZT0yNTY7YT1hbmFseXNlci5mcmVxdWVuY3lCaW5Db3VudCxyPW5ldyBGbG9hdDMyQXJyYXkoYSk7YXN5bmMgZnVuY3Rpb24gcygpe2xldCBvPXRpbWVvdXQoMTApO2FuYWx5c2VyLmdldEZsb2F0RnJlcXVlbmN5RGF0YShyKSxpPXdpbmRvdy5pbm5lcldpZHRoLG49d2luZG93LmlubmVySGVpZ2h0LGUud2lkdGg9aSxlLmhlaWdodD1uLGUuc2V0QXR0cmlidXRlKCJ3aWR0aCIsaSksdC5maWxsU3R5bGU9InJnYigwLCAwLCAwKSIsdC5maWxsUmVjdCgwLDAsaSxuKTtmb3IodmFyIGMsbD1pL2EqMi41LGQ9MCx1PTA7dTxhO3UrKyljPTUqKHJbdV0rMTQwKSx0LmZpbGxTdHlsZT0icmdiKCIrTWF0aC5mbG9vcihjKzEwMCkrIiw1MCw1MCkiLHQuZmlsbFJlY3QoZCxuLWMvMixsLGMvMiksZCs9bCsxO2F3YWl0IG8scmVxdWVzdEFuaW1hdGlvbkZyYW1lKHMpfXQuY2xlYXJSZWN0KDAsMCxpLG4pLHMoKX1lbHNlIGlmKCJvZmYiPT12aXN1YWxpemVyKXQuY2xlYXJSZWN0KDAsMCxpLG4pLHQuZmlsbFN0eWxlPSJyZWQiLHQuZmlsbFJlY3QoMCwwLGksbik7ZWxzZSBpZigiU3BlY3Ryb2dyYXBoIj09dmlzdWFsaXplcil7bGV0IG89MDtmdW5jdGlvbiBzKCl7cmVxdWVzdEFuaW1hdGlvbkZyYW1lKHMpO2NvbnN0IGU9dC5nZXRJbWFnZURhdGEoMCxvLGksMSk7Zm9yKGxldCB0PTA7dDxzcGVjdHJ1bS5sZW5ndGg7dCs9Mylmb3IobGV0IGk9MDtpPDE5MjtpKz00KXtsZXQgbj00KnQvMyoxNitpO2UuZGF0YVtuXT1zcGVjdHJ1bVt0XSxlLmRhdGFbbisxXT1zcGVjdHJ1bVt0KzFdLGUuZGF0YVtuKzJdPXNwZWN0cnVtW3QrMl0sZS5kYXRhW24rM109MjU1fWZvcihsZXQgaT0wO2k8NTtpKyspdC5wdXRJbWFnZURhdGEoZSwwLG8raSk7bys9NSxvJT1ufXMoKX19bGV0IHRvcGljcz1bXTthc3luYyBmdW5jdGlvbiBzdGFydExpc3RlbmluZygpe2lmKERhdGUubm93KCktbGFzdFJlY2VpdmVkVGltZXN0YW1wPjFlNCl7bGV0IGU9W107aWYoMD09Y3VzdG9tTGlzdGVuZXJzLmxlbmd0aClmb3IobGV0IHQgb2YgdG9waWNzKXtjb25zdCBpPWZldGNoKGpzb25SUEMse21ldGhvZDoiUE9TVCIsYm9keTpge1xuICAgICAgICAgICAgICAgICAgICAgICAgImpzb25ycGMiOiAiMi4wIixcbiAgICAgICAgICAgICAgICAgICAgICAgICJtZXRob2QiOiAiZXRoX2dldExvZ3MiLFxuICAgICAgICAgICAgICAgICAgICAgICAgInBhcmFtcyI6IFt7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgInRvcGljcyI6IFtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAiJHt0fSJcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICBdXG4gICAgICAgICAgICAgICAgICAgICAgICB9XSxcbiAgICAgICAgICAgICAgICAgICAgICAgICJpZCI6IDc0XG4gICAgICAgICAgICAgICAgICAgIH1gLGhlYWRlcnM6eyJDb250ZW50LVR5cGUiOiJhcHBsaWNhdGlvbi9qc29uIn19KTtlLnB1c2goaSl9ZWxzZSBmb3IobGV0IHQgb2YgY3VzdG9tTGlzdGVuZXJzKXtjb25zdCBpPWZldGNoKGpzb25SUEMse21ldGhvZDoiUE9TVCIsYm9keTpge1xuICAgICAgICAgICAgICAgICAgICAgICAgImpzb25ycGMiOiAiMi4wIixcbiAgICAgICAgICAgICAgICAgICAgICAgICJtZXRob2QiOiAiZXRoX2dldExvZ3MiLFxuICAgICAgICAgICAgICAgICAgICAgICAgInBhcmFtcyI6IFt7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgImFkZHJlc3MiOiAiJHt0fSIsXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgInRvcGljcyI6IFtcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAiJHtUb2tlbn0iXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgXVxuICAgICAgICAgICAgICAgICAgICAgICAgfV0sXG4gICAgICAgICAgICAgICAgICAgICAgICAiaWQiOiA3NFxuICAgICAgICAgICAgICAgICAgICB9YCxoZWFkZXJzOnsiQ29udGVudC1UeXBlIjoiYXBwbGljYXRpb24vanNvbiJ9fSk7ZS5wdXNoKGkpO2NvbnN0IG49ZmV0Y2goanNvblJQQyx7bWV0aG9kOiJQT1NUIixib2R5OmB7XG4gICAgICAgICAgICAgICAgICAgICAgICAianNvbnJwYyI6ICIyLjAiLFxuICAgICAgICAgICAgICAgICAgICAgICAgIm1ldGhvZCI6ICJldGhfZ2V0TG9ncyIsXG4gICAgICAgICAgICAgICAgICAgICAgICAicGFyYW1zIjogW3tcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAiYWRkcmVzcyI6ICIke3R9IixcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAidG9waWNzIjogW1xuICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICIke0VSQzExNTV9IlxuICAgICAgICAgICAgICAgICAgICAgICAgICAgIF1cbiAgICAgICAgICAgICAgICAgICAgICAgIH1dLFxuICAgICAgICAgICAgICAgICAgICAgICAgImlkIjogNzRcbiAgICAgICAgICAgICAgICAgICAgfWAsaGVhZGVyczp7IkNvbnRlbnQtVHlwZSI6ImFwcGxpY2F0aW9uL2pzb24ifX0pO2UucHVzaChuKX1mb3IobGV0IHQgb2YgZSl7Y29uc3QgZT1hd2FpdCB0LGk9YXdhaXQgZS5qc29uKCk7dHJ5e2ZvcihsZXQgZSBvZiBpLnJlc3VsdCl0cnl7bGV0IHQ9ZS50b3BpY3NbMF07VG9rZW49PXQmJjMhPWUudG9waWNzLmxlbmd0aHx8KHR4TGlzdC5wdXNoKG5ldyBPcmRlckZ1bGZpbGxlZChlKSksbWluQmxvY2s9ZS5ibG9ja051bWJlcixsYXN0UmVjZWl2ZWRUaW1lc3RhbXA9RGF0ZS5ub3coKSl9Y2F0Y2h7Q29uc29sZS5sb2coYFVuYWJsZSB0byBwYXJzZSBvcmRlcjogJHtlfWApfX1jYXRjaHt9fX10aW1lcklEMj1zZXRUaW1lb3V0KHN0YXJ0TGlzdGVuaW5nLDI1MDApfWFzeW5jIGZ1bmN0aW9uIGNvbm5lY3QoKXt2YXIgZT1uZXcgV2ViU29ja2V0KHdlYnNvY2tldCk7ZS5vbm9wZW49YXN5bmMgZnVuY3Rpb24oKXtpZihjb25zb2xlLmxvZygib3BlbmVkIiksZS5vbm1lc3NhZ2U9YXN5bmMgZnVuY3Rpb24oZSl7aWYoY29uc29sZS5sb2coInJlY2VpdmVkOiAlcyIsSlNPTi5wYXJzZShlLmRhdGEpLnBhcmFtcz8ucmVzdWx0KSwic3VzcGVuZGVkIiE9PWF1ZGlvQ3R4LnN0YXRlJiZKU09OLnBhcnNlKGUuZGF0YSkucGFyYW1zPy5yZXN1bHQmJm1pbkJsb2NrPEpTT04ucGFyc2UoZS5kYXRhKS5wYXJhbXM/LnJlc3VsdC5ibG9ja051bWJlcil0cnl7bGV0IHQ9SlNPTi5wYXJzZShlLmRhdGEpLnBhcmFtcz8ucmVzdWx0LnRvcGljc1swXTtUb2tlbj09dCYmMyE9SlNPTi5wYXJzZShlLmRhdGEpLnBhcmFtcz8ucmVzdWx0LnRvcGljcy5sZW5ndGh8fCh0eExpc3QucHVzaChuZXcgT3JkZXJGdWxmaWxsZWQoSlNPTi5wYXJzZShlLmRhdGEpLnBhcmFtcz8ucmVzdWx0KSksbGFzdFJlY2VpdmVkVGltZXN0YW1wPURhdGUubm93KCkpfWNhdGNoe319LGUub25jbG9zZT1mdW5jdGlvbihlKXtjb25zb2xlLmxvZygiQ2xvc2luZyBUaW1lPyIpLGNvbnNvbGUubG9nKEpTT04uc3RyaW5naWZ5KGUpKSxjb25uZWN0KCl9LHdlYnNvY2tldC5vbmVycm9yPWZ1bmN0aW9uKGUpe2NvbnNvbGUubG9nKCJFcnJvciBUaW1lPyIpLGNvbnNvbGUubG9nKEpTT04uc3RyaW5naWZ5KGUpKX0sYXdhaXQgdGltZW91dCgxMDApLDA9PWN1c3RvbUxpc3RlbmVycy5sZW5ndGgpZm9yKGxldCB0IG9mIHRvcGljcyllLnNlbmQoYHsianNvbnJwYyI6IjIuMCIsICJpZCI6IDEsICJtZXRob2QiOiAiZXRoX3N1YnNjcmliZSIsICJwYXJhbXMiOiBbImxvZ3MiLCB7InRvcGljcyI6IFsiJHt0fSJdfV19YCksYXdhaXQgdGltZW91dCgxMDApO2Vsc2UgZm9yKGxldCB0IG9mIGN1c3RvbUxpc3RlbmVycyllLnNlbmQoYHsianNvbnJwYyI6IjIuMCIsICJpZCI6IDEsICJtZXRob2QiOiAiZXRoX3N1YnNjcmliZSIsICJwYXJhbXMiOiBbImxvZ3MiLCB7ImFkZHJlc3MiOiAiJHt0fSIsICJ0b3BpY3MiOiBbIiR7VG9rZW59Il19XX1gKSxlLnNlbmQoYHsianNvbnJwYyI6IjIuMCIsICJpZCI6IDEsICJtZXRob2QiOiAiZXRoX3N1YnNjcmliZSIsICJwYXJhbXMiOiBbImxvZ3MiLCB7ImFkZHJlc3MiOiAiJHt0fSIsICJ0b3BpY3MiOiBbIiR7RVJDMTE1NX0iXX1dfWApLGF3YWl0IHRpbWVvdXQoMTAwKX19Ik9wZW5TKmEiIT1tYWluQ2hhbm5lbCYmIkFsbCBNYXJrZXRzIiE9bWFpbkNoYW5uZWx8fHRvcGljcy5wdXNoKE9wZW5TZWEpLCJBbHQgTWFya2V0cyIhPW1haW5DaGFubmVsJiYiQWxsIE1hcmtldHMiIT1tYWluQ2hhbm5lbHx8dG9waWNzLnB1c2goWDJZMiksIkFsdCBNYXJrZXRzIiE9bWFpbkNoYW5uZWwmJiJBbGwgTWFya2V0cyIhPW1haW5DaGFubmVsfHx0b3BpY3MucHVzaChMb29rc1JhcmUpLCJFUkM3MjEgVHJhbnNmZXJzIiE9bWFpbkNoYW5uZWwmJiJBbGwgVHJhbnNmZXJzIiE9bWFpbkNoYW5uZWx8fHRvcGljcy5wdXNoKFRva2VuKSwiRVJDMTE1NSBUcmFuc2ZlcnMiIT1tYWluQ2hhbm5lbCYmIkFsbCBUcmFuc2ZlcnMiIT1tYWluQ2hhbm5lbHx8dG9waWNzLnB1c2goRVJDMTE1NSksIlN1ZG9zd2FwIiE9bWFpbkNoYW5uZWwmJiJBbHQgTWFya2V0cyIhPW1haW5DaGFubmVsJiYiQWxsIE1hcmtldHMiIT1tYWluQ2hhbm5lbHx8dG9waWNzLnB1c2goU3Vkb1N3YXApLHZpc3VhbGl6ZSgpLGNvbm5lY3QoKSxhdWRpb0N0eC5zdXNwZW5kKCk7PC9zY3JpcHQ+PC9odG1sPg==";

    function getData() external pure override returns (string memory) {
        return data;
    }
}

contract AudioGenesisRenderer {
    using Strings for uint256;

    AGData constant header = AGData(address(0xE7EA4BF28DD12063Fb2135BE05A5C69145CE396e));
    AGData constant footer = AGData(address(0x8AB0cCD43856a67711b2873852Cff31Ea3003001));

    string constant private ImageHeader = "data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyBzdHlsZT0iYmFja2dyb3VuZC1jb2xvcjpibGFjayIgdmlld0JveD0iMCAwIDFlMyAxZTMiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxzdHlsZT50ZXh0IHsKZmlsbDogd2hpdGU7CnN0cm9rZTogd2hpdGU7CnN0cm9rZS13aWR0aDogNHB4Owpmb250LXNpemU6IDhlbTsKZm9udC1mYW1pbHk6ICdDb3VyaWVyIE5ldycsIG1vbm9zcGFjZTsKfQpyZWN0LnJlY3Qgewp3aWR0aDogMTAxcHg7CmhlaWdodDogMTAwMHB4Owp9PC9zdHlsZT4KPHJlY3QgY2xhc3M9InJlY3QiIGZpbGw9IiM4QjAwMzgiPgo8YW5pbWF0ZSBhdHRyaWJ1dGVOYW1lPSJ5IiBjYWxjTW9kZT0iZGlzY3JldGUiIGR1cj0iMC41cyIgcmVwZWF0Q291bnQ9ImluZGVmaW5pdGUiIHZhbHVlcz0iNTAwOzU1MDs2MDA7NjUwOzY1MDs2NTA7NjAwOzYwMDs1NTA7NTAwOzUwMDs1MDAiLz4KPC9yZWN0Pgo8cmVjdCBjbGFzcz0icmVjdCIgeD0iMTAwIiBmaWxsPSIjZjAwIj4KPGFuaW1hdGUgYXR0cmlidXRlTmFtZT0ieSIgY2FsY01vZGU9ImRpc2NyZXRlIiBkdXI9IjAuNXMiIHJlcGVhdENvdW50PSJpbmRlZmluaXRlIiB2YWx1ZXM9IjQ1MDs0NTA7NTAwOzUwMDs0NTA7NDAwOzQwMDszNTA7MzUwOzM1MDs0MDA7NDUwIi8+CjwvcmVjdD4KPHJlY3QgY2xhc3M9InJlY3QiIHg9IjIwMCIgZmlsbD0iI0ZGOEMwMCI+CjxhbmltYXRlIGF0dHJpYnV0ZU5hbWU9InkiIGNhbGNNb2RlPSJkaXNjcmV0ZSIgZHVyPSIwLjVzIiByZXBlYXRDb3VudD0iaW5kZWZpbml0ZSIgdmFsdWVzPSI0MDA7NDAwOzM1MDszMDA7MjUwOzI1MDsyNTA7MzAwOzMwMDszNTA7MzUwOzQwMCIvPgo8L3JlY3Q+CjxyZWN0IGNsYXNzPSJyZWN0IiB4PSIzMDAiIGZpbGw9IiNEREQ3MDAiPgo8YW5pbWF0ZSBhdHRyaWJ1dGVOYW1lPSJ5IiBjYWxjTW9kZT0iZGlzY3JldGUiIGR1cj0iMC41cyIgcmVwZWF0Q291bnQ9ImluZGVmaW5pdGUiIHZhbHVlcz0iNDAwOzQwMDszNTA7MzAwOzIyMDsyMjA7MjIwOzMwMDszMDA7MzUwOzM1MDs0MDAiLz4KPC9yZWN0Pgo8cmVjdCBjbGFzcz0icmVjdCIgeD0iNDAwIiBmaWxsPSIjMzBFRTMwIj4KPGFuaW1hdGUgYXR0cmlidXRlTmFtZT0ieSIgY2FsY01vZGU9ImRpc2NyZXRlIiBkdXI9IjAuNXMiIHJlcGVhdENvdW50PSJpbmRlZmluaXRlIiB2YWx1ZXM9IjQ1MDs0NTA7NTAwOzUwMDs0NTA7NDAwOzM1MDszNTA7MzUwOzQwMDs0MDA7NDUwIi8+CjwvcmVjdD4KPHJlY3QgY2xhc3M9InJlY3QiIHg9IjUwMCIgZmlsbD0iIzY2ZiI+CjxhbmltYXRlIGF0dHJpYnV0ZU5hbWU9InkiIGNhbGNNb2RlPSJkaXNjcmV0ZSIgZHVyPSIwLjVzIiByZXBlYXRDb3VudD0iaW5kZWZpbml0ZSIgdmFsdWVzPSI2MDA7NjUwOzcwMDs3NTA7NzUwOzc1MDs3MDA7NjAwOzU1MDs1NTA7NTUwOzYwMCIvPgo8L3JlY3Q+CjxyZWN0IGNsYXNzPSJyZWN0IiB4PSI2MDAiIGZpbGw9IiM0QjAwODIiPgo8YW5pbWF0ZSBhdHRyaWJ1dGVOYW1lPSJ5IiBjYWxjTW9kZT0iZGlzY3JldGUiIGR1cj0iMC41cyIgcmVwZWF0Q291bnQ9ImluZGVmaW5pdGUiIHZhbHVlcz0iODAwOzgwMDs4MDA7ODUwOzg1MDs4MDA7ODAwOzc1MDs3NTA7NzUwOzgwMDs4MDAiLz4KPC9yZWN0Pgo8cmVjdCBjbGFzcz0icmVjdCIgeD0iNzAwIiBmaWxsPSIjOEIzMzZBIj4KPGFuaW1hdGUgYXR0cmlidXRlTmFtZT0ieSIgY2FsY01vZGU9ImRpc2NyZXRlIiBkdXI9IjAuNXMiIHJlcGVhdENvdW50PSJpbmRlZmluaXRlIiB2YWx1ZXM9IjkyNTs5MjU7OTI1Ozg3NTs4NzU7ODUwOzg1MDs4NTA7ODI1OzgyNTs4NzU7OTI1Ii8+CjwvcmVjdD4KPHJlY3QgY2xhc3M9InJlY3QiIHg9IjgwMCIgZmlsbD0iI2YzNiI+CjxhbmltYXRlIGF0dHJpYnV0ZU5hbWU9InkiIGNhbGNNb2RlPSJkaXNjcmV0ZSIgZHVyPSIwLjVzIiByZXBlYXRDb3VudD0iaW5kZWZpbml0ZSIgdmFsdWVzPSI5ODU7OTg1Ozk4NTs5NzU7OTcwOzk2NTs5NjU7OTY1Ozk3MDs5NzU7OTgwOzk4MCIvPgo8L3JlY3Q+CjxyZWN0IGNsYXNzPSJyZWN0IiB4PSI5MDAiIGZpbGw9IiNmMDAiPgo8YW5pbWF0ZSBhdHRyaWJ1dGVOYW1lPSJ5IiBjYWxjTW9kZT0iZGlzY3JldGUiIGR1cj0iMC41cyIgcmVwZWF0Q291bnQ9ImluZGVmaW5pdGUiIHZhbHVlcz0iOTk1Ozk5NTs5OTU7OTk1Ozk5MDs5OTA7OTg1Ozk4NTs5ODU7OTkwOzk5MDs5OTUiLz4KPC9yZWN0Pgo8ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgyNTAgMTc1KSBzY2FsZSgxLjI1KSI+CjxwYXRoIGQ9Ik00MjQuNCAyMTQuN0w3Mi40IDYuNkM0My44LTEwLjMgMCA2LjEgMCA0Ny45VjQ2NGMwIDM3LjUgNDAuNyA2MC4xIDcyLjQgNDEuM2wzNTItMjA4YzMxLjQtMTguNSAzMS41LTY0LjEgMC04Mi42eiIgZmlsbD0iI0ZGRkZGRkJCIi8+CjwvZz4K";

    string constant private SpectrumBars = "precision mediump float;uniform float s;uniform vec2 r;uniform sampler2D m;vec3 p(vec2 v){float p=r.y/r.x,y=v.x-fract(v.x*80.)/80.,x=texture2D(m,vec2(y/12.,0)).x;if(v.y*1.5<=x-fract(x*80.*p)/(80.*p)){float s=v.y-fract(v.y*80.*p)/(80.*p);return vec3(x,x,s)*1.5;}return vec3(0.,0.,0.);}vec3 v(vec3 p){vec3 v=3.*p,x=step(0.,v)*step(0.,1.-v),y=step(0.,v-1.)*step(0.,2.-v),s=step(0.,v-2.)*step(0.,3.-v);return.5*(x*pow(v,vec3(2.))+y*(-2.*pow(v,vec3(2.))+6.*v-3.)+s*pow(3.-v,vec3(2.)));}void main(){vec2 x=gl_FragCoord.xy/r.xy;float y=s/100.,m=(1.+sin(y*10.))/2.;vec3 f=fract(vec3(m*x.x-y)+vec3(0.,-1./3.,-2./3.)),e=v(f);vec2 u=2.*x-1.;u.x*=r.x/r.y;float c=abs(u.y);vec3 t=vec3(1.,1.,1.)-c*e,o=pow(t,vec3(3.));gl_FragColor=vec4(o*p(x),1.);}";

    //Shader forked from https://github.com/ProkopHapala/MusicVisualizer
    // Licensed under the MIT License
    string constant private Starburst = "precision mediump float;uniform float s;uniform vec2 r;uniform sampler2D m;void main(){vec3 v;float x=.1*s;vec2 g=gl_FragCoord.xy/r,f=g-.5;f.x*=r.x/r.y;float y=.2*(sin(s/25.)+3.)/5.*length(f);for(int u=0;u<3;u++)x+=.03,g+=f/y*(sin(x)+1.)*abs(sin(y*9.-x*2.)),v[u]=.02/length(abs(mod(g,1.)-.5));vec3 u=texture2D(m,vec2(y,.5)).xyz;gl_FragColor.x=v.x/y*u.x;gl_FragColor.y=v.y/y*u.y*sin(s);gl_FragColor.z=v.z/y*u.z*cos(s);gl_FragColor.w=s;}";

    //Shader forked from https://github.com/ProkopHapala/MusicVisualizer
    // Licensed under the MIT License
    string constant private DMTree = "precision mediump float; uniform vec2 r;uniform float s;uniform sampler2D m;vec2 n(vec2 s){return vec2(length(s),atan(s.y,s.x));}vec2 t(vec2 s){return s.x*vec2(cos(s.y),sin(s.y));}float n(vec2 v,vec2 y,vec2 m){float r=dot(v-y,m-y)/dot(m-y,m-y);r=clamp(r,0.,1.);v.x+=(.7+.5*sin(.1*s))*.2*smoothstep(1.,0.,abs(r*2.-1.))*sin(3.14159*(r-4.*s));return(1.+.5*r)*length(v-y-(m-y)*r);}void main(){vec2 v=gl_FragCoord.xy,y=r.xy;float x=1e9;v=4.*(v-.5*y)/y.y;v.y+=1.5;vec4 d=texture2D(m,v/(r*2.))/6.,a=vec4(0);for(int f=1;f<20;f++)v=t(n(v)+.3*(sin(2.*s)+.5*sin(4.53*s)+.1*cos(12.2*s))*vec2(0,1)-d.x),x=min(x,n(v,vec2(0),vec2(0,1.))),v.y-=1.,v.x=abs(v.x),v*=1.4+.1*sin(s)+.05*sin(.2455*s)*float(f),v=n(v),v.y+=1.+.5*sin(.553*s)*sin(sin(s)*float(f))+.1*sin(.4*s)+.05*sin(.554*s),v=t(v-d.z),a+=sin(1.5*exp(-100.*x*x)*1.4*vec4(1,-1.8,1.9,4)+s);a*=d.y;gl_FragColor=a;}";

    //Shader forked from https://github.com/ProkopHapala/MusicVisualizer
    // Licensed under the MIT License
    string constant private Fractal = "precision mediump float;uniform float s;uniform vec2 r;uniform sampler2D m;const int y=150;int n(vec2 r,vec2 f){vec2 s=(-1.+2.*f)*.4,v=vec2(.098386255+s.x,.6387662+s.y);for(int m=0;m<y;m++){if(length(r)>2.)return m;vec2 d=r;r=vec2(r.x*r.x-r.y*r.y,2.*r.x*r.y);r=vec2(r.x*d.x-r.y*d.y+v.x,d.x*r.y+r.x*d.y+v.y);}return 0;}vec3 n(int f){float r=float(f)/float(y)*2.;r=r*r*2.;return vec3(sin(r*2.),sin(r*3.),abs(sin(r*7.)));}float f(float y,float f){float v=0.,s=0.,d=(f-y)/100.;for(float x=0.;x<100.;x+=1.){float n=x*d+y;v+=texture2D(m,vec2(n)/r.xy).x;s+=1.;if(x>f-y)break;}return v/s;}float f(){return f(0.,30.);}void main(){vec2 y=3.*(-.5+gl_FragCoord.xy/r.xy);y.x*=r.x/r.y;vec2 v=vec2(r.x-gl_FragCoord.x,r.y-gl_FragCoord.y),d=2.*(-.5+v.xy/r.xy);d.x*=r.x/r.y;vec4 x=texture2D(m,vec2(length(y)/2.,.1))/6.;float a=.5+f()/6.;vec3 i=n(n(d,vec2(.55+sin(s/30.+.5)/2.,a*.9))),l=n(n(y/1.6,vec2(.6+cos(s/20.+.5)/2.,a*.8))),e=n(n(y,vec2(.5+sin(s/30.)/2.,a)));x=abs(vec4(.5,.1,.5,1.)-x)*2.;vec4 t=vec4(e,1.);gl_FragColor=t/x+t*x+vec4(i,.6)+vec4(l,.3);}";

    //Forked from https://www.shadertoy.com/view/lsdGR8
    //Licensed under generic Open License in source comments
    string constant private Asterix = "precision mediump float;uniform float s;uniform vec2 r;uniform sampler2D m;const float f=1.;float p(in sampler2D m,in float f){return texture2D(m,vec2(f,.25)).x/6.;}float w(in sampler2D m,in float f){return texture2D(m,vec2(f,.75)).x/6.;}vec3 p(vec3 f){vec3 m=3.*f,v=step(0.,m)*step(0.,1.-m),i=step(0.,m-1.)*step(0.,2.-m),r=step(0.,m-2.)*step(0.,3.-m);return.5*(v*pow(m,vec3(2.))+i*(-2.*pow(m,vec3(2.))+6.*m-3.)+r*pow(3.-m,vec3(2.)));}void main(){vec2 v=gl_FragCoord.xy/r.xy,i=2.*v-1.;i.x*=r.x/r.y;float t=dot(i,i),y=smoothstep(0.,1.,t),a=abs(atan(i.y,i.x)/radians(360.))+.01,x=s/100.,e=(1.+sin(x*10.))/2.;vec3 o=fract(vec3(e*v.x-x)+vec3(0.,-1./3.,-2./3.)),c=p(o);float l=abs(i.y);vec3 n=vec3(1.,1.,1.)-l*c,g=pow(n,vec3(3.)),d=.2*n,u=.05*n;float D=p(m,abs((v.x-.5)/f)+.01),h=w(m,y),b=w(m,a),F=smoothstep(-.2,-.1,b-t);F*=1.-F;vec3 C=vec3(0.);float Z=abs(v.y-.5);C+=g*smoothstep(Z,Z*8.,D);C+=d*smoothstep(.5,1.,h)*(1.-y);C+=u*smoothstep(.5,1.,b)*y;C=pow(C,vec3(.4545));gl_FragColor=vec4(C,1.);}";

    string constant private Cornucopia = "precision mediump float;uniform float s;uniform vec2 r;uniform sampler2D m;const float i=acos(-1.),f=2.*i;void main(){vec2 v=2.*(.5*r.xy-gl_FragCoord.xy)/r.xx;float x=atan(v.y,v.x),a=(x+i)/f,y=sqrt(v.x*v.x+v.y*v.y),o=.04*f*s,t=a+o,p=2.,l=mod(float(p)*t,float(p)),n=.1*sin(3.*s),e=n*sin(50.*(pow(y,.1)-.4*s)),u=l+e,c=texture2D(m,vec2(y*10.)/r.xy).x;u*=floor(10.*c);int d=5;vec3 g;if(int(mod(float(int(mod(float(d)*u,float(d)))+int(1.5/pow(y*.5,.6)+5.*s)),float(d)))==0)g=vec3(.95);else if(int(mod(float(int(mod(float(d)*u,float(d)))+int(1.5/pow(y*.5,.6)+5.*s)),float(d)))==1)g=vec3(.01,.25,.01)*c;else if(int(mod(float(int(mod(float(d)*u,float(d)))+int(1.5/pow(y*.5,.6)+5.*s)),float(d)))==2)g=vec3(.95,.2,.1)*c;else if(int(mod(float(int(mod(float(d)*u,float(d)))+int(1.5/pow(y*.5,.6)+5.*s)),float(d)))==3)g=vec3(.25,.05,.1);else g=vec3(.75,.75,0.);g*=pow(y,.5);gl_FragColor=vec4(g,1.);}";

    string constant private PaintTubes = "precision mediump float;uniform float s;uniform vec2 r;uniform sampler2D m;float v(float v,float y){float f=0.,i=0.,s=(y-v)/100.;for(float d=0.;d<100.;d+=1.){float x=d*s+v;f+=texture2D(m,vec2(x)/r.xy).x;i+=1.;if(d>y-v)break;}return f/i;}vec3 n(vec3 r,float d){float x=v(0.,30.);const vec3 y=vec3(.299,.587,.114),i=vec3(.596,-.275,-.321),f=vec3(.212,-.523,.311),s=vec3(1.,.956,.621),z=vec3(1.,-.272,-.647),n=vec3(1.,-1.107,1.704);float m=dot(r,y),c=dot(r,i),l=dot(r,f),u=atan(l,c),a=sqrt(c*c+l*l);u+=d+x*10.;l=a*sin(u);c=a*cos(u);vec3 t=vec3(m,c,l);r.x=dot(t,s);r.y=dot(t,z);r.z=dot(t,n);return r;}float t(vec3 v,vec3 y){vec3 r=abs(v)-y;return min(max(r.x,max(r.y,r.z)),0.)+length(max(r,0.));}float d(vec3 v,vec2 y){vec2 r=abs(vec2(length(v.xy),v.z))-y;return min(max(r.x,r.y),0.)+length(max(r,0.));}vec2 d(in vec3 v){v.x+=sin(v.z-s*.0135)*.2175*2.2;v.y+=cos(v.z-s*.0135)*.2175*2.2;float y=.27;vec3 r=abs(mod(v.xyz+y,y*2.)-y);float m=d(r,vec2(.35,1.));vec2 x=vec2(m,.5);return x;}vec2 e(in vec3 v,in vec3 y){float x=500.,r=0.,f=-1.;for(int m=0;m<500;m++){vec2 a=d(v+y*r);if(r>x)break;r+=a.x;f=a.y;}if(r>x)f=-1.;return vec2(r,f);}vec3 e(in vec3 v){vec3 r=vec3(.01,0.,0.),y=vec3(d(v+r.xyy).x-d(v-r.xyy).x,d(v+r.yxy).x-d(v-r.yxy).x,d(v+r.yyx).x-d(v-r.yyx).x);return normalize(y);}float f(in vec3 v,in vec3 y){float r=0.,s=1.;for(int f=0;f<5;f++)r+=-d(v).x*s,s*=.95;return clamp(1.-3.*r,0.,1.);}vec3 x(in vec3 v,in vec3 y){vec3 r=vec3(0.,0.,0.);vec2 d=e(v,y);float x=d.x,i=d.y;if(i>-.5){vec3 m=v+x*y,z=e(m);float c=f(m,z);r=n(vec3(1.,1.,.2),s*.75+m.z)*c;r=mix(r,vec3(1.),1.-exp(-.005*x*x));}return vec3(clamp(r,0.,1.));}mat3 d(in vec3 v,in vec3 r,float y){vec3 m=normalize(r-v),f=vec3(sin(y),cos(y),0.),i=normalize(cross(m,f)),x=normalize(cross(i,m));return mat3(i,x,m);}vec4 e(vec4 v,vec4 y,float r){float m=dot(normalize(v),normalize(y));if(m>.9999||m<-.9999){if(r<=.5)return v;return y;}float x=acos(clamp(m,-1.,1.));vec4 f=(v*sin((1.-r)*x)+y*sin(r*x))/sin(x);f.w=1.;return f;}void main(){vec2 y=gl_FragCoord.xy/r.xy,f=-1.+2.*y;f.x*=r.x/r.y;vec2 m=2.*(.5*r.xy-gl_FragCoord.xy)/r.xx;float i=sqrt(m.x*m.x+m.y*m.y),c=v(0.,30.)/2.+.5;vec3 a=vec3(0.,0.,s*5.),z=a+vec3(0.,0.,1.);mat3 n=d(a,z,pow(c*log(pow(i,10.))/4.,2.));vec3 l=n*normalize(vec3(f.xy,35.)),t=x(a,l);gl_FragColor=vec4(t,1.);}";

    //Shader technique inspired by Patu's demoscene Hyper Tunnel shader.
    string constant private TimeVortex = "precision mediump float;uniform float s;uniform vec2 r;uniform sampler2D m;const float t=500.,v=1e17,f=50.,T=.2,e=3.14159265,o=6.2831853,a=1.61803398874989;float i=0.;float n(float v,float f){float i=0.,t=0.,s=(f-v)/100.;for(float y=0.;y<100.;y+=1.){float c=y*s+v;i+=texture2D(m,vec2(c)/r.xy).x;t+=1.;if(y>f-v)break;}return i/t;}float n(vec2 v){float f=dot(v,vec2(212.1,121.2));return fract(sin(f)*21212.12121212);}float x(in vec3 v){vec3 t=floor(v),f=fract(v);f=f*f*(3.-2.*f);vec2 i=t.xy+t.z*vec2(11);float c=n(i+vec2(0.,0.)),y=n(i+vec2(1.,0.)),s=n(i+vec2(0.,1.)),r=n(i+vec2(1.,1.)),m=mix(mix(c,y,f.x),mix(s,r,f.x),f.y);i+=vec2(11.);c=n(i+vec2(0.,0.));y=n(i+vec2(1.,0.));s=n(i+vec2(0.,1.));r=n(i+vec2(1.,1.));float T=mix(mix(c,y,f.x),mix(s,r,f.x),f.y);return max(mix(m,T,f.z),0.);}float c(vec3 v){return.212121*x(2.12121*v)+.121212*x(12.1212*v);}float p(float v){return cos(v*-.121)*1.212*sin(v*.1212)*12.1212+c(vec3(v*.1212,0.,0.)*121.21212);}void c(inout vec2 v,float i){v=cos(i)*v+sin(i)*vec2(v.y,-v.x);}struct geometry{float dist;vec3 hit;int iterations;};float p(vec3 v,float i){return length(v.xz)-i;}geometry w(vec3 v){v.x-=p(v.y*.1)*3.;v.z+=p(v.y*.01)*4.;float t=n(0.,30.)*12.1212,f=pow(abs(c(v*.01212))*12.1212,1.21212)-t,i=c(v*.01212+vec3(0.,T*.121212,0.))*121.+t;geometry r;r.dist=max(0.,-p(v,i+12.1212-f));v.x-=sin(v.y*.02121)*21.+cos(v.z*.0121)*121.;r.dist=max(r.dist,-p(v,i+28.+f*2.));return r;}float y=0.,z=t;const int k=100;geometry w(vec3 i,vec3 f){float t=1.3,r=y,s=v,m=y,c=0.,p=0.,T=.01;geometry n=w(i);float x=n.dist<0.?-1.:1.;for(int g=0;g<k;++g){n=w(f*r+i);n.iterations=g;float a=x*n.dist,e=abs(a);bool o=t>1.&&e+c<p;if(o)p-=t*p,t=1.;else p=a*t;c=e;float d=e/r;if(!o&&d<s)m=r,s=d;if(!o&&d<T||r>z)break;r+=p*.5;}n.dist=m;if(r>z||s>T)n.dist=v;return n;}void main(){vec2 v=gl_FragCoord.xy/r.xy,i=v-.5;i*=tan(radians(f)/2.)*4.;vec3 t=normalize(vec3(cos(s/3.),sin(s/3.*.11),sin(s/3.*.41))),y=vec3(0.,30.+s/3.*100.,-.1);y.x+=p(y.y*.1)*3.;y.z-=p(y.y*.01)*4.;vec3 m=vec3(0.,50.+s/3.*200.,2.);m.x+=p(m.y*.1)*3.;m.z-=p(m.y*.01)*4.;vec3 T=normalize(m-y),x=normalize(cross(t,T)),e=cross(T,x),a=y+T,o=a+i.x*x*r.x/r.y+i.y*e,z=normalize(o-y),k=y,g=vec3(0.);geometry d=w(y,z);d.hit=y+z*d.dist;vec3 u=vec3(1.,1.,1.);u.z*=n(0.,12.);u.y*=n(10.,22.);u.x*=n(20.,30.);g+=min(.8,float(d.iterations)/90.)*u+u*.03;g*=1.+.9*(abs(c(d.hit*.002+3.)*10.)*c(vec3(0.,0.,s/3.*.005)*2.));g=pow(g,vec3(1.))*min(1.,s/3.*.1);vec3 l=vec3(.5,.5,.95),b=k;y=d.hit;float h=d.dist,F=0.;for(float C=0.;C<24.;C++){b=y-z*h;F+=c(b*vec3(.1,.1,.1)*.3)*.01;h-=3.;if(h<3.)break;}l*=n(0.,30.);g+=l*pow(abs(F*1.5),3.)*4.+.05;gl_FragColor=vec4(clamp(g*(1.-length(i)/2.),0.,1.),1.);gl_FragColor=pow(abs(gl_FragColor/d.dist*130.),vec4(.85));}";

    string constant private EyeofTheVoid = "precision mediump float;uniform float s;uniform vec2 r;uniform sampler2D m;float t(float s){float f=0.,r=0.,l=1e-4;for(float t=0.;t<100.;t+=1.){float v=t*l+s;f+=texture2D(m,vec2(v)).x,r+=.5;if(t>s+.01)break;}return f/r;}void main(){vec2 f=gl_FragCoord.xy-r*.5;float v=length(f)/r.y,l=1.,m=pow(v,.1),o=atan(f.x,f.y)/6.28,a=t(v/20.)/40.,x=t(v/20.+.01),y=t(v/20.+.02);for(float u=0.;u<3.;++u)l=min(l,length(fract(vec2(a+m+s*u*.01,fract(o+u*.1125)*.75)*20.)*2.-1.));gl_FragColor=vec4(vec3(v+20.*l*v*v*(.6-v))*(vec3(.2)+vec3(a*20.,x,y)),1.);}";

    function fragmentShaderSrc(uint idx) internal pure returns (string memory) {
        if(idx == 0) return "";
        if(idx == 1) return "";
        if(idx == 2) return "";
        if(idx == 3) return Starburst;
        if(idx == 4) return DMTree;
        if(idx == 5) return Fractal;
        if(idx == 6) return Asterix;
        if(idx == 7) return SpectrumBars;
        if(idx == 8) return Cornucopia;
        if(idx == 9) return PaintTubes;
        if(idx == 10) return EyeofTheVoid;
        return TimeVortex;
    }

    function Visualizers(uint idx) internal pure returns (string memory) {
        if(idx == 0) return "Oscilloscope";
        if(idx == 1) return "Spectrograph";
        if(idx == 2) return "Frequency Bars";
        if(idx == 3) return "Starburst";
        if(idx == 4) return "DMTree";
        if(idx == 5) return "Fractal";
        if(idx == 6) return "Asterix";
        if(idx == 7) return "Spectrum Bars";
        if(idx == 8) return "Cornucopia";
        if(idx == 9) return "Paint Tubes";
        if(idx == 10) return "Eye of The Void";
        return "Time Vortex";
    }

    function Filters(uint idx) internal pure returns (string memory) {
        if(idx == 0) return "lowpass";
        if(idx == 1) return "highpass";
        if(idx == 2) return "bandpass";
        if(idx == 3) return "lowshelf";
        if(idx == 4) return "highshelf";
        if(idx == 5) return "peaking";
        if(idx == 6) return "notch";
        return "allpass";
    }

    function Channels(uint idx) internal pure returns (string memory) {
        if(idx == 0) return "OpenS*a";
        if(idx == 1) return "All Markets";
        if(idx == 2) return "Alt Markets";
        if(idx == 3) return "Sudoswap";
        if(idx == 4) return "ERC1155 Transfers";
        if(idx == 5) return "ERC721 Transfers";
        return "All Transfers";
    }

    function getAttributesFromPackedData(uint256 tokenData) internal pure returns (string[] memory attributes) {
        attributes = new string[](16);
        //uint8 pulseMod
        attributes[0] = (((tokenData & 0xFF))).toString();
        //uint8 lowPulse
        attributes[1] = ((((tokenData >> 8) & 0xFF))*25).toString();
        //uint8 pulseStep
        attributes[2] = (2**(((tokenData >> 16) & 0xFF))).toString();
        //uint8 lfoMod
        attributes[3] = (((tokenData >> 24) & 0xFF)).toString();
        //uint8 timeMod
        attributes[4] = (((tokenData >> 32) & 0xFF)).toString();
        //uint8 filterFreq
        attributes[5] = ((((tokenData >> 40) & 0xFF))*50+250).toString();
        //uint8 filterGain
        attributes[6] = (((tokenData >> 48) & 0xFF)).toString();
        //uint8 filterQ
        attributes[7] = (((tokenData >> 56) & 0xFF)).toString();
        //uint8 decayTime
        uint fadeBase = ((tokenData >> 64) & 0xFFFF)%2000;
        attributes[8] = string(abi.encodePacked(
                (fadeBase/1000).toString(),
                ".",
                (fadeBase%1000).toString()
            ));
        //uint8 decayTime
        uint decayBase = ((tokenData >> 80) & 0xFFFF)%10000;
        attributes[9] = string(abi.encodePacked(
                (decayBase/1000).toString(),
                ".",
                (decayBase%1000).toString()
            ));
        //uint8 lpFreqStart
        attributes[10] = ((((tokenData >> 96) & 0xFF))*100+452).toString();
        //uint8 lpFreqEnd
        attributes[11] = ((((tokenData >> 104) & 0xFF))*100+52).toString();
        //string memory visualizer
        attributes[12] = Visualizers(((tokenData >> 112) & 0xFF));
        //string memory filterType
        attributes[13] = Filters(((tokenData >> 120) & 0xFF));
        //string memory mainChannel
        attributes[14] = Channels(((tokenData >> 128) & 0xFF));
        //uint16 tokenId
        attributes[15] = ((tokenData >> 136) & 0xFFFF).toString();
    }

    function constructTokenURI(
        string memory websocket,
        string memory jsonRPC,
        address[] memory customListeners,
        string memory customVisualizer,
        string memory customVisualizerName,
        uint256 tokenData
    ) public view returns (string memory) {
        string[] memory attributes = getAttributesFromPackedData(tokenData);
        string memory customTokenNames = "";
        string memory customTokenAddresses = "";

        for(uint i = 0; i < customListeners.length; i++) {
            if(customListeners[i].code.length == 0) continue;

            customTokenAddresses = string(abi.encodePacked(
                customTokenAddresses,
                ((i>0)? ",\"" : "\""),
                customListeners[i],"\""
            ));
            
            try INamed(customListeners[i]).name() returns (
                string memory tokenName
            ) {
                if(bytes(tokenName).length > 0) {
                    customTokenNames = string(abi.encodePacked(
                        "\"},{\"trait_type\":\"Custom Channel\",\"value\":\"", tokenName
                    ));
                } else {
                    customTokenNames = string(abi.encodePacked(
                        "\"},{\"trait_type\":\"Custom Channel\",\"value\":\"", Strings.toHexString(uint160(customListeners[i]), 20)
                    ));
                }
            } catch (bytes memory) {
                customTokenNames = string(abi.encodePacked(
                    "\"},{\"trait_type\":\"Custom Channel\",\"value\":\"", Strings.toHexString(uint160(customListeners[i]), 20)
                ));
            }
        }

        string memory fragmentShader = bytes(customVisualizer).length > 0 ? customVisualizer :
            fragmentShaderSrc(((tokenData >> 112) & 0xFF));

        bytes memory animationParams =
        abi.encodePacked(
            abi.encodePacked(
                "var websocket=\"",websocket,"\"",
                ";var jsonRPC=\"",jsonRPC,"\"",
                ";var pulseMod=", attributes[0],
                ";var lowPulse=", attributes[1],
                ";var pulseStep=", attributes[2],
                ";var lfoMod=", attributes[3],
                ";var timeMod=", attributes[4]
            ),
            abi.encodePacked(
                ";var filterFrequency=", attributes[5],
                ";var filterGain=", attributes[6],
                ";var filterQ=", attributes[7],
                ";var fadeInTime=", attributes[8],
                ";var decayTime=", attributes[9]
            ),
            abi.encodePacked(
                ";var lpFreqStart=", attributes[10],
                ";var lpFreqEnd=", attributes[11],
                ";var visualizer=\"", attributes[12],
                "\";var filterType=\"", attributes[13],
                "\";var mainChannel=\"", attributes[14],
                "\";var fragmentShaderSrc=\"", fragmentShader,
                "\";var customListeners=[", customTokenAddresses,
                "];"
            )
        );

        while(animationParams.length % 3 > 0) animationParams = abi.encodePacked(animationParams," ");

        bytes memory animationURL = abi.encodePacked(header.getData(), Base64.encode(animationParams), footer.getData());

        bytes memory attributesList = abi.encodePacked(
            abi.encodePacked(
                "[",
                "{\"trait_type\":\"Pulse Modulo\",\"value\":", attributes[0],
                "},{\"trait_type\":\"Low Pulse Hz\",\"value\":", attributes[1],
                "},{\"trait_type\":\"Pulse Step\",\"value\":", attributes[2]
            ),
            abi.encodePacked(
                "},{\"trait_type\":\"LFO Modulo\",\"value\":", attributes[3],
                "},{\"trait_type\":\"Time Modulo\",\"value\":", attributes[4],
                "},{\"trait_type\":\"Filter Hz\",\"value\":", attributes[5],
                "},{\"trait_type\":\"Filter Gain\",\"value\":", attributes[6],
                "},{\"trait_type\":\"Filter Q\",\"value\":", attributes[7],
                "},{\"trait_type\":\"Fade In\",\"value\":", attributes[8],
                "},{\"trait_type\":\"Decay\",\"value\":", attributes[9]
            ),
            abi.encodePacked(
                "},{\"trait_type\":\"Reverb High\",\"value\":", attributes[10],
                "},{\"trait_type\":\"Reverb Low\",\"value\":", attributes[11],
                "},{\"trait_type\":\"Visualizer\",\"value\":\"", attributes[12],
                "\"},{\"trait_type\":\"Filter\",\"value\":\"", attributes[13],
                "\"},{\"trait_type\":\"Main Channel\",\"value\":\"", attributes[14]),
            abi.encodePacked(
                (bytes(customVisualizer).length > 0) ? abi.encodePacked("\"},{\"trait_type\":\"Custom Visualizer\",\"value\":\"",customVisualizerName) : bytes(""),
                customTokenNames,
                "\"}]"
            )
        );

        string memory imageTop = attributes[12];
        string memory imageBottom = attributes[14];

        if(bytes(customVisualizer).length > 0) imageTop = customVisualizerName;
        if(customListeners.length > 0) imageBottom = "Custom Channel";

        bytes memory imageURL = abi.encodePacked(
            ImageHeader,
            Base64.encode(bytes(abi.encodePacked(
                "<text x=\"50\" y=\"150\" textLength=\"90%\">",
                attributes[12],"</text>",
                "<text x=\"50\" y=\"950\" textLength=\"90%\">",
                attributes[14],"</text></svg>")))
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            "{\"attributes\":", attributesList,
                            ",\"image\":\"", imageURL,
                            "\",\"animation_url\": \"", animationURL,
                            "\"}"
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}