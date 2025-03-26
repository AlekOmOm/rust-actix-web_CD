import React, { useState, useEffect } from "react";
import "./App.css"; // Or your main CSS file

function App() {
  const [backendMessage, setBackendMessage] = useState("Loading...");

  useEffect(() => {
    // Fetch root message
    fetch("/")
      .then((response) => {
        if (!response.ok)
          throw new Error(`HTTP error! status: ${response.status}`);
        return response.text();
      })
      .then((data) => setBackendMessage(data))
      .catch((error) => {
        console.error("Error fetching root:", error);
        setBackendMessage(`Error loading data: ${error.message}`);
      });
  }, []);

  return (
    <div className="App">
      <h1>React Frontend</h1>
      <p>Backend Root says: {backendMessage}</p>
      <h2>Users List:</h2>
    </div>
  );
}

export default App;
