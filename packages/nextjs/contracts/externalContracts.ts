import { Abi_CrowdFund } from "../../hardhat/generated/abis/CrowdFund";
import { GenericContractsDeclaration } from "~~/utils/scaffold-eth/contract";

const externalContracts = {
  11155111: {
    CrowdFund: {
      address: "0xfa0782f654ddc4fc347f43e374a39327d05824b6",
      abi: Abi_CrowdFund,
    },
  },
} as const;

export default externalContracts satisfies GenericContractsDeclaration;
