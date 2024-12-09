import axios from "axios"

var getLens = async (imageUrl) => {
  try {
    // Codifica a URL para passá-la como parâmetro
    const encodedUrl = encodeURIComponent(imageUrl);

    const response = await axios.get(`http://localhost:5000/?image=${encodedUrl}`);

    // Loga e retorna a resposta
    console.log("Server Response:", response.data);
    return response.data; // Mantém a funcionalidade de retorno
  } catch (error) {
    console.error("Error sending GET request:", error.message);
    return []
  }
};

export { getLens };
