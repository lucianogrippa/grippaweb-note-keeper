import CryptoJS from "crypto-js";

export const LOCAL_TOKEN_KEY=CryptoJS.SHA256("LOCAL_TOKEN_DATA").toString(CryptoJS.enc.Base64);