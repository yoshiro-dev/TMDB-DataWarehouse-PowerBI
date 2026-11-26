const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');

const campos = ['pelicula_id', 'budget', 'runtime', 'release_year', 'revenue'];

// 1. Extraer la fuente de conocimiento. El CSV contiene solo enteros.
function leerCSV() {
    const texto = fs.readFileSync(path.join(__dirname, 'peliculas.csv'), 'utf8');
    const [encabezado, ...filas] = texto.trim().split(/\r?\n/);
    if (encabezado.replace(/^\uFEFF/, '') !== campos.join(',')) {
        throw new Error('El encabezado del CSV no coincide.');
    }
    const ids = new Set();
    return filas.map((fila, i) => {
        const celdas = fila.split(',');
        const numeros = celdas.map(Number);
        if (celdas.length !== campos.length ||
            celdas.some(c => !/^\d+$/.test(c)) ||
            numeros.some(n => !Number.isSafeInteger(n) || n <= 0)) {
            throw new Error(`Registro inválido en línea ${i + 2}`);
        }
        const [pelicula_id, budget, runtime, release_year, revenue] = numeros;
        if (ids.has(pelicula_id)) throw new Error(`ID duplicado: ${pelicula_id}`);
        ids.add(pelicula_id);
        return { pelicula_id, budget, runtime, release_year, revenue };
    });
}

// 2. Resumen de los registros extraídos, sin entrenar ningún modelo.
const peliculas = leerCSV();
if (!peliculas.length) throw new Error('La fuente de conocimiento está vacía.');
const resumen = {
    registros: peliculas.length,
    campos,
    entradas: ['budget', 'runtime', 'release_year'],
    objetivo: 'revenue',
    anioMin: Math.min(...peliculas.map(p => p.release_year)),
    anioMax: Math.max(...peliculas.map(p => p.release_year)),
    muestra: peliculas.slice(0, 5)
};

console.log(`Fuente cargada: ${resumen.registros} películas`);
console.log(`Años: ${resumen.anioMin}–${resumen.anioMax}`);
if (process.argv.includes('--check')) {
    console.log('CSV validado: IDs únicos y valores enteros positivos.');
} else {
    // 3. Servidor local: solo la interfaz y un endpoint de lectura.
    const archivos = {
        '/': ['index.html', 'text/html; charset=utf-8'],
        '/style.css': ['style.css', 'text/css; charset=utf-8']
    };
    const server = http.createServer((req, res) => {
        if (req.method !== 'GET') { res.writeHead(405); return res.end(); }
        if (req.url === '/api/fuente') {
            res.writeHead(200, {'Content-Type': 'application/json; charset=utf-8'});
            return res.end(JSON.stringify(resumen));
        }
        const archivo = archivos[req.url];
        if (!archivo || !Object.hasOwn(archivos, req.url)) {
            res.writeHead(404); return res.end('No encontrado');
        }
        res.writeHead(200, {'Content-Type': archivo[1]});
        res.end(fs.readFileSync(path.join(__dirname, archivo[0])));
    });
    server.listen(3000, '127.0.0.1', () => console.log('http://localhost:3000'));
}
