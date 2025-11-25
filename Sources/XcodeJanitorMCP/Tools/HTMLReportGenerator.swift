import Foundation

/// Generates an interactive HTML report from unused assets data
struct HTMLReportGenerator {
    
    static func generateHTML(from report: [String: Any], outputPath: String) throws {
        let html = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Unused Assets Report</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: #f5f5f7;
            padding: 20px;
            color: #1d1d1f;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
        }
        
        .header h1 {
            font-size: 32px;
            font-weight: 600;
            margin-bottom: 10px;
        }
        
        .header .meta {
            opacity: 0.9;
            font-size: 14px;
        }
        
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            padding: 30px;
            border-bottom: 1px solid #e5e5e7;
        }
        
        .stat-card {
            background: #f5f5f7;
            padding: 20px;
            border-radius: 8px;
        }
        
        .stat-card .label {
            font-size: 12px;
            text-transform: uppercase;
            color: #86868b;
            font-weight: 500;
            margin-bottom: 8px;
        }
        
        .stat-card .value {
            font-size: 28px;
            font-weight: 600;
            color: #1d1d1f;
        }
        
        .controls {
            padding: 20px 30px;
            background: #fafafa;
            border-bottom: 1px solid #e5e5e7;
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
            align-items: center;
        }
        
        .search-box {
            flex: 1;
            min-width: 250px;
        }
        
        input[type="text"] {
            width: 100%;
            padding: 10px 15px;
            border: 1px solid #d2d2d7;
            border-radius: 6px;
            font-size: 14px;
            transition: border-color 0.2s;
        }
        
        input[type="text"]:focus {
            outline: none;
            border-color: #667eea;
        }
        
        select {
            padding: 10px 15px;
            border: 1px solid #d2d2d7;
            border-radius: 6px;
            font-size: 14px;
            background: white;
            cursor: pointer;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
        }
        
        thead {
            background: #f5f5f7;
            position: sticky;
            top: 0;
            z-index: 10;
        }
        
        th {
            padding: 15px 20px;
            text-align: left;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            color: #86868b;
            cursor: pointer;
            user-select: none;
            border-bottom: 2px solid #e5e5e7;
        }
        
        th:hover {
            background: #ebebed;
        }
        
        th.sortable::after {
            content: ' ⇅';
            opacity: 0.3;
        }
        
        th.sorted-asc::after {
            content: ' ↑';
            opacity: 1;
        }
        
        th.sorted-desc::after {
            content: ' ↓';
            opacity: 1;
        }
        
        tbody tr {
            border-bottom: 1px solid #f5f5f7;
            transition: background-color 0.15s;
        }
        
        tbody tr:hover {
            background: #f9f9fb;
        }
        
        td {
            padding: 15px 20px;
            font-size: 14px;
        }
        
        td.path-cell {
            max-width: 300px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }
        
        .asset-name {
            font-weight: 500;
            color: #1d1d1f;
        }
        
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 500;
            text-transform: uppercase;
        }
        
        .badge-image {
            background: #e3f2fd;
            color: #1976d2;
        }
        
        .badge-color {
            background: #fce4ec;
            color: #c2185b;
        }
        
        .badge-data {
            background: #f3e5f5;
            color: #7b1fa2;
        }
        
        .size-mb {
            font-weight: 500;
            color: #667eea;
        }
        
        .path {
            font-size: 12px;
            color: #86868b;
            font-family: 'SF Mono', Monaco, monospace;
        }
        
        .no-results {
            padding: 60px;
            text-align: center;
            color: #86868b;
        }
        
        .footer {
            padding: 20px 30px;
            text-align: center;
            font-size: 12px;
            color: #86868b;
            border-top: 1px solid #e5e5e7;
        }
        
        @media (max-width: 768px) {
            .container {
                border-radius: 0;
            }
            
            .summary {
                grid-template-columns: 1fr;
            }
            
            table {
                font-size: 12px;
            }
            
            th, td {
                padding: 10px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🧹 Unused Assets Report</h1>
            <div class="meta">
                <span id="generated-date"></span> • 
                <span id="project-path"></span>
            </div>
        </div>
        
        <div class="summary">
            <div class="stat-card">
                <div class="label">Total Assets</div>
                <div class="value" id="total-assets">-</div>
            </div>
            <div class="stat-card">
                <div class="label">Unused Assets</div>
                <div class="value" id="unused-count">-</div>
            </div>
            <div class="stat-card">
                <div class="label">Total Size</div>
                <div class="value" id="total-size">- MB</div>
            </div>
            <div class="stat-card">
                <div class="label">Space Savings</div>
                <div class="value" id="savings-percent">-%</div>
            </div>
        </div>
        
        <div class="controls">
            <div class="search-box">
                <input type="text" id="search" placeholder="🔍 Search by asset name...">
            </div>
            <select id="type-filter">
                <option value="">All Types</option>
                <option value="imageset">Images</option>
                <option value="colorset">Colors</option>
                <option value="dataset">Data</option>
            </select>
            <select id="catalog-filter">
                <option value="">All Catalogs</option>
            </select>
        </div>
        
        <table>
            <thead>
                <tr>
                    <th class="sortable" data-sort="name">Asset Name</th>
                    <th>Type</th>
                    <th>Catalog</th>
                    <th class="sortable" data-sort="size">Size</th>
                    <th>Path</th>
                </tr>
            </thead>
            <tbody id="assets-table">
            </tbody>
        </table>
        
        <div class="footer">
            Generated by xcode-janitor-mcp • <span id="asset-count">0</span> assets shown
        </div>
    </div>
    
    <script>
        const reportData = {{REPORT_DATA}};
        
        let currentSort = { key: 'size', direction: 'desc' };
        let filteredAssets = [];
        
        // Initialize
        function init() {
            const summary = reportData.summary;
            document.getElementById('generated-date').textContent = new Date(reportData.generated_at).toLocaleString();
            document.getElementById('project-path').textContent = reportData.project_path.split('/').pop();
            document.getElementById('total-assets').textContent = summary.total_assets_scanned.toLocaleString();
            document.getElementById('unused-count').textContent = summary.unused_count.toLocaleString();
            document.getElementById('total-size').textContent = summary.total_size_mb + ' MB';
            
            const savingsPercent = ((summary.unused_count / summary.total_assets_scanned) * 100).toFixed(1);
            document.getElementById('savings-percent').textContent = savingsPercent + '%';
            
            // Populate catalog filter
            const catalogs = [...new Set(reportData.unused_assets.map(a => a.catalog))];
            const catalogFilter = document.getElementById('catalog-filter');
            catalogs.forEach(catalog => {
                const option = document.createElement('option');
                option.value = catalog;
                option.textContent = catalog;
                catalogFilter.appendChild(option);
            });
            
            filteredAssets = reportData.unused_assets;
            sortAndRender();
            
            // Event listeners
            document.getElementById('search').addEventListener('input', filterAssets);
            document.getElementById('type-filter').addEventListener('change', filterAssets);
            document.getElementById('catalog-filter').addEventListener('change', filterAssets);
            
            document.querySelectorAll('th.sortable').forEach(th => {
                th.addEventListener('click', () => sortBy(th.dataset.sort));
            });
        }
        
        function filterAssets() {
            const search = document.getElementById('search').value.toLowerCase();
            const typeFilter = document.getElementById('type-filter').value;
            const catalogFilter = document.getElementById('catalog-filter').value;
            
            filteredAssets = reportData.unused_assets.filter(asset => {
                const matchesSearch = asset.name.toLowerCase().includes(search);
                const matchesType = !typeFilter || asset.type === typeFilter;
                const matchesCatalog = !catalogFilter || asset.catalog === catalogFilter;
                return matchesSearch && matchesType && matchesCatalog;
            });
            
            sortAndRender();
        }
        
        function sortBy(key) {
            if (currentSort.key === key) {
                currentSort.direction = currentSort.direction === 'asc' ? 'desc' : 'asc';
            } else {
                currentSort.key = key;
                currentSort.direction = key === 'name' ? 'asc' : 'desc';
            }
            sortAndRender();
        }
        
        function sortAndRender() {
            // Sort
            filteredAssets.sort((a, b) => {
                let valA, valB;
                
                switch(currentSort.key) {
                    case 'name':
                        valA = a.name.toLowerCase();
                        valB = b.name.toLowerCase();
                        break;
                    case 'size':
                        valA = a.size_bytes;
                        valB = b.size_bytes;
                        break;
                    default:
                        return 0; // No sorting
                }
                
                if (valA < valB) return currentSort.direction === 'asc' ? -1 : 1;
                if (valA > valB) return currentSort.direction === 'asc' ? 1 : -1;
                return 0;
            });
            
            // Update sort indicators
            document.querySelectorAll('th').forEach(th => {
                th.classList.remove('sorted-asc', 'sorted-desc');
            });
            const sortedTh = document.querySelector(`th[data-sort="${currentSort.key}"]`);
            if (sortedTh) {
                sortedTh.classList.add(currentSort.direction === 'asc' ? 'sorted-asc' : 'sorted-desc');
            }
            
            renderTable();
        }
        
        function renderTable() {
            const tbody = document.getElementById('assets-table');
            tbody.innerHTML = '';
            
            if (filteredAssets.length === 0) {
                tbody.innerHTML = '<tr><td colspan="5" class="no-results">No assets found</td></tr>';
                document.getElementById('asset-count').textContent = '0';
                return;
            }
            
            filteredAssets.forEach(asset => {
                const tr = document.createElement('tr');
                
                const typeBadgeClass = asset.type === 'imageset' ? 'badge-image' : 
                                      asset.type === 'colorset' ? 'badge-color' : 'badge-data';
                
                tr.innerHTML = `
                    <td class="asset-name">${escapeHtml(asset.name)}</td>
                    <td><span class="badge ${typeBadgeClass}">${asset.type.replace('set', '')}</span></td>
                    <td>${escapeHtml(asset.catalog)}</td>
                    <td class="size-mb">${asset.size_mb} MB</td>
                    <td class="path-cell"><span class="path">${escapeHtml(asset.path.split('/').slice(-3).join('/'))}</span></td>
                `;
                
                tbody.appendChild(tr);
            });
            
            document.getElementById('asset-count').textContent = filteredAssets.length.toLocaleString();
        }
        
        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
        
        // Initialize on load
        init();
    </script>
</body>
</html>
"""
        
        // Convert report to JSON string and embed in HTML
        let jsonData = try JSONSerialization.data(withJSONObject: report, options: [])
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
        let finalHTML = html.replacingOccurrences(of: "{{REPORT_DATA}}", with: jsonString)
        
        try finalHTML.write(toFile: outputPath, atomically: true, encoding: .utf8)
    }
}
