import axios from "axios"

var url = "https://lensimage.site/api/"

var getLens = async (imageUrl) => {
  try {
    // Codifica a URL para passá-la como parâmetro
    const encodedUrl = encodeURIComponent(imageUrl);

    const response = await axios.get(`${url}?image=${encodedUrl}`);

    // Loga e retorna a resposta
    console.log("Server Response:", response.data);
    return response.data; // Mantém a funcionalidade de retorno
  } catch (error) {
    console.error("Error sending GET request:", error.message);
    return []
  }
};

export { getLens };
